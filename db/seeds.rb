# Loads the Rails Guides corpus (db/corpus, see its README) and indexes every section.
#
# Sections go in with insert_all, which runs no callbacks, and are then indexed in batches, the
# way a backfill of an existing table would be. A guide already in the database is left alone, so
# the seed can be re-run after the corpus changes for the guides that are new.

new_guide_ids = Rails.root.join("db/corpus").glob("*.yml").sort.filter_map do |path|
  data = YAML.safe_load_file(path)
  next if Guide.exists?(slug: data.fetch("slug"))

  guide = Guide.create!(data.slice("slug", "title", "description", "url", "source"))
  now = Time.current
  rows = data.fetch("sections").each_with_index.map do |section, index|
    {
      guide_id: guide.id, position: index + 1, anchor: section.fetch("anchor"), title: section.fetch("title"),
      parent_title: section["parent"], body: section.fetch("body"), created_at: now, updated_at: now
    }
  end
  Section.insert_all!(rows)
  puts "#{guide.title}: #{rows.size} sections"
  guide.id
end

if new_guide_ids.any?
  ActiveSearch.index_names.each do |name|
    ActiveSearch.index(name).batch(max_size: 500) do |batch|
      Section.includes(:guide).where(guide_id: new_guide_ids).find_each { |section| batch.add(section) }
    end
    puts "indexed #{name}"
  end
end
