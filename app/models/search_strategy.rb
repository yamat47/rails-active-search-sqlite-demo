# One of the three FTS5 tokenizers the demo compares, paired with the index built with it.
#
# Not an Active Record model: the three are fixed by the migrations in db/migrate, and the demo
# page shows them side by side for the same query.
class SearchStrategy
  attr_reader :key, :index, :tokenize, :title, :summary, :migration_line, :snippet_words

  # FTS5's snippet() measures its window in tokens of the index's tokenizer: 30 words for
  # unicode61 and porter, but 30 trigrams, about 30 characters, for trigram, so that one asks for
  # more. FTS5 caps the window at 64 tokens, so a trigram snippet never exceeds about 64 characters.
  def initialize(key:, index:, tokenize:, title:, summary:, migration_line:, snippet_words: 30)
    @key = key
    @index = index
    @tokenize = tokenize
    @title = title
    @summary = summary
    @migration_line = migration_line
    @snippet_words = snippet_words
  end

  ALL = [
    new(
      key: "unicode61",
      index: :sections,
      tokenize: "unicode61",
      title: "unicode61 (the default)",
      summary: "What `rails generate active_search:document` writes. Words are split on spaces and " \
               "punctuation, underscores included, and matched as they are: \"callback\" does not find " \
               "\"callbacks\", and has_many is the two words has and many.",
      migration_line: %q(create_virtual_table :section_documents_fts, :fts5, [ "title", "body" ])
    ),
    new(
      key: "porter",
      index: :porter_sections,
      tokenize: "porter",
      title: "porter",
      summary: "One option added to the generated migration, as the Active Search README suggests: " \
               "the Porter stemmer reduces words to a stem, so \"validate\", \"validation\" and " \
               "\"validations\" are one token, and so are a few words that only look alike.",
      migration_line: %q(create_virtual_table :porter_section_documents_fts, :fts5, [ "title", "body", "tokenize='porter'" ])
    ),
    new(
      key: "trigram",
      index: :trigram_sections,
      tokenize: "trigram",
      title: "trigram",
      summary: "Every three characters is a token, so a query matches inside a word: \"callba\" " \
               "finds callbacks and \"find_b\" finds find_by. A query of one or two characters " \
               "matches nothing, short queries match widely, and snippets are short: FTS5 caps " \
               "them at 64 tokens, which here means 64 characters.",
      migration_line: %q(create_virtual_table :trigram_section_documents_fts, :fts5, [ "title", "body", "tokenize='trigram'" ]),
      snippet_words: 64
    )
  ].freeze

  class << self
    def all = ALL

    def find(key) = ALL.find { |strategy| strategy.key == key } or raise ArgumentError, "no tokenizer #{key}"
  end

  def search(query, guide_id: nil, limit: 10)
    search = Section.search(query, index: index)
      .highlight(title: true, body: { snippet: { words: snippet_words } })
      .limit(limit)
    search = search.filter(guide_id: guide_id) if guide_id.present?
    search.results
  end

  # The ids of every section the query finds. The limit is the most the SQLite adapter pages to
  # and more than the corpus has sections; a filter field as the hit field, so that no section
  # text travels for an id.
  def ids(query)
    Section.search(query, index: index).hit_fields(:guide_id).limit(10_000).results.map(&:id)
  end

  # The tokens FTS5 sees for +text+: a query here is tokenized the same way the indexed text was.
  def tokens(text)
    Fts5Tokenizer.tokens(text, tokenize: tokenize)
  end
end
