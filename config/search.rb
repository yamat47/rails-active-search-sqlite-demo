# Three indexes over the same sections of the Rails Guides. The fields are identical; what differs
# is the FTS5 tokenizer in each index's migration (db/migrate).

# As the generator writes it: FTS5's default unicode61 tokenizer. A word matches only itself, so
# "callback" does not find "callbacks".
ActiveSearch.define_index(:sections) do
  text :title
  text :body
  string :guide_title
  integer :guide_id
end

# tokenize='porter': the Porter stemmer over unicode61, which is what the Active Search README
# suggests for English. "callback", "callbacks" and "callbacks'" become one token.
ActiveSearch.define_index(:porter_sections, source: "Section") do
  text :title
  text :body
  string :guide_title
  integer :guide_id
end

# tokenize='trigram': every three characters is a token, so a query matches inside a word
# ("callba" finds callbacks, "find_b" finds find_by) and a query shorter than three characters
# matches nothing.
ActiveSearch.define_index(:trigram_sections, source: "Section") do
  text :title
  text :body
  string :guide_title
  integer :guide_id
end
