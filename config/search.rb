# Three indexes over the same paragraphs. The fields are identical; what differs is the FTS5
# tokenizer in each index's migration (db/migrate) and, for :segmented_paragraphs, that the text is
# split into words before it is written (Paragraph#to_segmented_document).

# As the generator writes it: FTS5's default unicode61 tokenizer, which keeps a run of Japanese
# characters as one token.
ActiveSearch.define_index(:paragraphs) do
  text :body
  string :author
  string :work_title
  integer :work_id
end

# tokenize='trigram': every three characters is a token, so a query of three or more characters
# matches anywhere in the text, and a shorter one matches nothing.
ActiveSearch.define_index(:trigram_paragraphs, source: "Paragraph") do
  text :body
  string :author
  string :work_title
  integer :work_id
end

# unicode61 again, over text that TinySegmenter has split into space-separated words.
ActiveSearch.define_index(:segmented_paragraphs, source: "Paragraph") do
  text :body
  string :author
  string :work_title
  integer :work_id
end
