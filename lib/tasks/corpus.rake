require "json"
require "net/http"
require "yaml"

namespace :corpus do
  desc "Download the works in db/corpus/works.yml from the aozorahack mirror and write db/corpus/<card_id>.txt"
  task fetch: :environment do
    mirror = "aozorahack/aozorabunko_text"
    corpus_dir = Rails.root.join("db/corpus")
    works = YAML.load_file(corpus_dir.join("works.yml"))

    http_get = lambda do |url|
      uri = URI(url)
      headers = { "User-Agent" => "rails-active-search-sqlite-demo corpus:fetch" }
      # Anonymous calls to the contents API are capped at 60 per hour, which is plenty
      # for a handful of authors; a token only matters when the task is run repeatedly.
      if uri.host == "api.github.com" && ENV["GITHUB_TOKEN"].present?
        headers["Authorization"] = "Bearer #{ENV["GITHUB_TOKEN"]}"
      end
      response = Net::HTTP.get_response(uri, headers)
      raise "GET #{url} failed: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)
      response.body.b
    end

    # One listing per author serves every work by that author.
    listings = Hash.new do |cache, person|
      entries = JSON.parse(http_get.call("https://api.github.com/repos/#{mirror}/contents/cards/#{person}/files"))
      cache[person] = entries.filter_map { |entry| entry["name"] if entry["type"] == "dir" }
    end

    # A card can ship several text variants. The ruby one carries the full text, and
    # a higher trailing number is a later revision of the file.
    pick_dir = lambda do |dirs, card_id|
      pattern = /\A#{card_id}_(ruby|txt)(?:_(\d+))?\z/
      dirs.filter_map { |name| (match = name.match(pattern)) && [ name, match[1] == "ruby" ? 1 : 0, match[2].to_i ] }
          .max_by { |_, variant, revision| [ variant, revision ] }
          &.first
    end

    # The mirror keeps Aozora's original Shift_JIS files; CP932 covers the vendor
    # extensions some of them use. A UTF-8 file is passed through untouched.
    to_utf8 = lambda do |bytes|
      utf8 = bytes.dup.force_encoding(Encoding::UTF_8)
      utf8.valid_encoding? ? utf8 : bytes.force_encoding(Encoding::Windows_31J).encode(Encoding::UTF_8)
    end

    render = lambda do |work, cleaned, source_url|
      front_matter = {
        "title" => cleaned[:title],
        "author" => cleaned[:author],
        "card_id" => work["card_id"],
        "card_url" => format("https://www.aozora.gr.jp/cards/%06d/card%d.html", work["person_id"], work["card_id"]),
        "source_url" => source_url,
        "colophon" => cleaned[:colophon]
      }
      YAML.dump(front_matter, line_width: -1) + "---\n" + cleaned[:paragraphs].join("\n") + "\n"
    end

    works.each do |work|
      person = format("%06d", work["person_id"])
      dir = pick_dir.call(listings[person], work["card_id"])
      abort "#{work["card_id"]}: no text directory under cards/#{person}/files in #{mirror}" unless dir

      source_url = "https://raw.githubusercontent.com/#{mirror}/master/cards/#{person}/files/#{dir}/#{dir}.txt"
      cleaned = Aozora::TextCleaner.call(to_utf8.call(http_get.call(source_url)))

      # The card ids in works.yml were looked up by hand, so make sure each one
      # really is the work it claims to be before anything lands in the repository.
      unless cleaned[:title] == work["title"] && cleaned[:author] == work["author"]
        abort "#{work["card_id"]}: expected #{work["title"]} / #{work["author"]}, got #{cleaned[:title]} / #{cleaned[:author]}"
      end

      # A gaiji outside the mapping is lost from the text, which is worth knowing but
      # not worth failing the whole fetch over.
      cleaned[:unmapped_gaiji].each do |note|
        warn "#{work["card_id"]}: dropped gaiji with unmapped code: ※［＃#{note}］"
      end

      path = corpus_dir.join("#{work["card_id"]}.txt")
      content = render.call(work, cleaned, source_url)
      if path.exist? && path.read == content
        puts "unchanged #{path.relative_path_from(Rails.root)}"
      else
        path.write(content)
        puts "wrote #{path.relative_path_from(Rails.root)} (#{cleaned[:paragraphs].size} paragraphs)"
      end
    end

    # works.yml is the single source of truth, so a work removed from it disappears here too.
    expected = works.map { |work| "#{work["card_id"]}.txt" }
    corpus_dir.glob("*.txt").each do |path|
      next if expected.include?(path.basename.to_s)

      path.delete
      puts "removed #{path.relative_path_from(Rails.root)} (not in works.yml)"
    end
  end
end
