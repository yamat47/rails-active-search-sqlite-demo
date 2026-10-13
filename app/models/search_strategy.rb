# One of the three ways the demo tokenizes Japanese for FTS5, paired with the index built that way.
#
# Not an Active Record model: the three are fixed by the migrations in db/migrate, and the demo
# page shows them side by side for the same query.
class SearchStrategy
  attr_reader :key, :index, :tokenize, :title, :summary, :migration_line

  def initialize(key:, index:, tokenize:, title:, summary:, migration_line:, segmented: false)
    @key = key
    @index = index
    @tokenize = tokenize
    @title = title
    @summary = summary
    @migration_line = migration_line
    @segmented = segmented
  end

  ALL = [
    new(
      key: "unicode61",
      index: :paragraphs,
      tokenize: "unicode61",
      title: "unicode61 (the default)",
      summary: "What `rails generate active_search:document` writes. unicode61 splits on spaces and " \
               "punctuation, so a run of kanji and kana is one token and a query matches only a whole run.",
      migration_line: %q(create_virtual_table :paragraph_documents_fts, :fts5, [ "body" ])
    ),
    new(
      key: "trigram",
      index: :trigram_paragraphs,
      tokenize: "trigram",
      title: "trigram",
      summary: "One option added to the generated migration. Every three characters is a token, so a " \
               "query of three or more characters matches inside a sentence, and a shorter one matches nothing.",
      migration_line: %q(create_virtual_table :trigram_paragraph_documents_fts, :fts5, [ "body", "tokenize='trigram'" ])
    ),
    new(
      key: "segmented",
      index: :segmented_paragraphs,
      tokenize: "unicode61",
      title: "words + unicode61",
      summary: "The generated migration again, but the text is split into words by TinySegmenter before it " \
               "is indexed, and the query goes through the same split. Short words match; split mistakes show.",
      migration_line: %q(create_virtual_table :segmented_paragraph_documents_fts, :fts5, [ "body" ]),
      segmented: true
    )
  ].freeze

  class << self
    def all = ALL
  end

  def segmented? = @segmented

  # What Active Search is given. Only the segmented index rewrites the query, with the same split
  # its documents went through.
  def query_text(query)
    segmented? ? TinySegmenter.wakati(query) : query
  end

  def search(query, author: nil, limit: 10)
    search = Paragraph.search(query_text(query), index: index)
      .highlight(body: { snippet: { words: 30 } })
      .limit(limit)
    search = search.filter(author: author) if author.present?
    search.results
  end

  # The tokens FTS5 sees for +text+: a query here is tokenized the same way the indexed text was.
  def tokens(text)
    Fts5Tokenizer.tokens(query_text(text), tokenize: tokenize)
  end

  # The segmented index keeps the spaces TinySegmenter put in, so a highlight reads "渋谷 区"; the
  # spaces between two Japanese characters (or a character and a mark tag) are taken back out for
  # display. The input is the escaped HTML Active Search returns, so the result stays safe.
  def display_highlight(html)
    return html unless segmented? && html

    html.gsub(/(?<=[^\x00-\x7F]|>) (?=[^\x00-\x7F]|<)/, "").html_safe # rubocop:disable Rails/OutputSafety
  end
end
