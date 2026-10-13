# Loads the Aozora Bunko corpus (db/corpus, see its README) and indexes every paragraph.
#
# Paragraphs go in with insert_all, which runs no callbacks, and are then indexed in batches, the
# way a backfill of an existing table would be. A work already in the database is left alone, so
# the seed can be re-run after adding a work to the corpus.

new_work_ids = Rails.root.join("db/corpus").glob("*.txt").sort.filter_map do |path|
  front_matter, body = File.read(path).delete_prefix("---\n").split("\n---\n", 2)
  attributes = YAML.safe_load(front_matter)
  next if Work.exists?(card_id: attributes.fetch("card_id"))

  work = Work.create!(attributes.slice("title", "author", "card_id", "card_url", "colophon"))
  now = Time.current
  rows = body.lines(chomp: true).reject(&:blank?).each_with_index.map do |text, index|
    { work_id: work.id, position: index + 1, body: text, created_at: now, updated_at: now }
  end
  Paragraph.insert_all!(rows)
  puts "#{work.title} (#{work.author}): #{rows.size} paragraphs"
  work.id
end

if new_work_ids.any?
  ActiveSearch.index_names.each do |name|
    ActiveSearch.index(name).batch(max_size: 500) do |batch|
      Paragraph.includes(:work).where(work_id: new_work_ids).find_each { |paragraph| batch.add(paragraph) }
    end
    puts "indexed #{name}"
  end
end
