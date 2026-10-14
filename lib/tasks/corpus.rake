require "json"
require "net/http"
require "yaml"

namespace :corpus do
  desc "Download the Rails Guides for the app's Rails version, split them into sections and write db/corpus/<slug>.yml"
  task fetch: :environment do
    repository = "rails/rails"
    corpus_dir = Rails.root.join("db/corpus")
    readme_path = corpus_dir.join("README.md")
    readme_markers = [ "<!-- corpus:fetch start -->", "<!-- corpus:fetch end -->" ]
    headers = { "User-Agent" => "rails-active-search-sqlite-demo corpus:fetch" }

    # Returns nil for a 404 so that callers can tell "no such ref" from a real failure.
    read_response = lambda do |response, url|
      case response
      when Net::HTTPSuccess then response.body.force_encoding(Encoding::UTF_8)
      when Net::HTTPNotFound then nil
      else raise "GET #{url} failed: #{response.code} #{response.message}"
      end
    end

    fetch_source = lambda do |http, ref, name|
      path = "/#{repository}/#{ref}/guides/source/#{name}"
      read_response.call(http.get(path, headers), "https://#{http.address}#{path}")
    end

    # Anonymous calls to the API are rate limited, so a token may be sent here; it never
    # goes to any other host.
    newest_tag = lambda do |prefix|
      url = "https://api.github.com/repos/#{repository}/git/matching-refs/tags/#{prefix}"
      api_headers = headers.merge("Accept" => "application/vnd.github+json")
      api_headers["Authorization"] = "Bearer #{ENV["GITHUB_TOKEN"]}" if ENV["GITHUB_TOKEN"].present?
      body = read_response.call(Net::HTTP.get_response(URI(url), api_headers), url)
      tags = JSON.parse(body.to_s).map { |entry| entry["ref"].delete_prefix("refs/tags/") }
      tags.max_by { |tag| Gem::Version.new(tag.delete_prefix("v")) } || abort("no tag matching #{prefix} in #{repository}")
    end

    # Psych only picks the literal style for strings that contain a newline; a section
    # with a single paragraph should read the same way as every other one.
    dump_yaml = lambda do |data|
      tree = Psych::Visitors::YAMLTree.create(line_width: -1)
      tree << data
      tree.tree.grep(Psych::Nodes::Mapping).each do |mapping|
        mapping.children.each_slice(2) do |key, value|
          value.style = Psych::Nodes::Scalar::LITERAL if key.value == "body" && value.is_a?(Psych::Nodes::Scalar)
        end
      end
      tree.tree.yaml(nil, line_width: -1)
    end

    write_if_changed = lambda do |path, content|
      if path.exist? && path.read == content
        false
      else
        path.write(content)
        true
      end
    end

    changes = 0
    guides = []

    Net::HTTP.start("raw.githubusercontent.com", 443, use_ssl: true) do |http|
      # The guides to search are the ones for the Rails version the app runs. A tag can
      # be missing for a while after a release is cut; the newest tag of the same minor
      # series is then the closest match.
      ref = ENV.fetch("GUIDES_REF") { "v#{Rails.version}" }
      index = fetch_source.call(http, ref, "documents.yaml")
      if index.nil?
        abort "#{ref}: guides/source/documents.yaml not found in #{repository}" if ENV["GUIDES_REF"].present?

        ref = newest_tag.call("v#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}.")
        index = fetch_source.call(http, ref, "documents.yaml") || abort("#{ref}: guides/source/documents.yaml not found in #{repository}")
      end
      series = ref[/\Av(\d+\.\d+)/, 1] || "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
      puts "fetching guides from #{repository} at #{ref}"

      # The per-version release notes are changelogs rather than prose and would dominate the index,
      # so they stay out; the upgrading guide that shares their group in documents.yaml stays in.
      documents = YAML.safe_load(index)
                      .flat_map { |group| group["documents"] }
                      .reject { |document| document["work_in_progress"] || document["url"].end_with?("_release_notes.html") }

      documents.each do |document|
        slug = document["url"].delete_suffix(".html")
        markdown = fetch_source.call(http, ref, "#{slug}.md") || abort("#{slug}: guides/source/#{slug}.md not found at #{ref}")
        split = RailsGuides::SectionSplitter.call(markdown)

        guide = {
          "slug" => slug,
          "title" => split[:title] || document["name"],
          "description" => document["description"].to_s.squish,
          "url" => "https://guides.rubyonrails.org/v#{series}/#{slug}.html",
          "source" => "https://github.com/#{repository}/blob/#{ref}/guides/source/#{slug}.md",
          "ref" => ref,
          "sections" => split[:sections].map { |section| section.transform_keys(&:to_s) }
        }
        guides << guide

        path = corpus_dir.join("#{slug}.yml")
        if write_if_changed.call(path, dump_yaml.call(guide))
          changes += 1
          puts "wrote #{path.relative_path_from(Rails.root)} (#{guide["sections"].size} sections)"
        else
          puts "unchanged #{path.relative_path_from(Rails.root)}"
        end
      end

      # documents.yaml is the single source of truth, so a guide dropped from it disappears here too.
      expected = guides.map { |guide| "#{guide["slug"]}.yml" }
      corpus_dir.glob("*.yml").sort.each do |path|
        next if expected.include?(path.basename.to_s)

        path.delete
        changes += 1
        puts "removed #{path.relative_path_from(Rails.root)} (not in documents.yaml)"
      end

      # The README keeps a table of the guides between two marker comments; the prose
      # around it is written by hand.
      sections = guides.sum { |guide| guide["sections"].size }
      rows = guides.map { |guide| "| [#{guide["title"]}](#{guide["url"]}) | `#{guide["slug"]}` | #{guide["sections"].size} |" }
      listing = <<~MARKDOWN
        #{readme_markers.first}
        Source: [#{repository} at `#{ref}`](https://github.com/#{repository}/tree/#{ref}/guides/source), fetched by `bin/rails corpus:fetch`.

        | Guide | File | Sections |
        | --- | --- | ---: |
        #{rows.join("\n")}

        #{guides.size} guides, #{ActiveSupport::NumberHelper.number_to_delimited(sections)} sections in total.
        #{readme_markers.last}
      MARKDOWN
      readme = readme_path.read
      if readme.include?(readme_markers.first) && readme.include?(readme_markers.last)
        updated = readme.sub(/#{Regexp.escape(readme_markers.first)}.*#{Regexp.escape(readme_markers.last)}\n/m) { listing }
        if write_if_changed.call(readme_path, updated)
          changes += 1
          puts "wrote #{readme_path.relative_path_from(Rails.root)}"
        end
      else
        warn "#{readme_path.relative_path_from(Rails.root)}: markers not found, table not updated"
      end

      bytes = corpus_dir.glob("*.yml").sum(&:size)
      puts "#{guides.size} guides, #{sections} sections, #{bytes} bytes in #{corpus_dir.relative_path_from(Rails.root)}"
      puts(changes.zero? ? "no changes" : "#{changes} file(s) changed")
    end
  end
end
