# One document and one query, as each of the three tokenizers sees them: the tokens of both, and
# whether, and where, the document matches. The explanation page's playground.
class TokenizerPlayground
  # What the search page shows for a query, too, so the reader can get from one to the other.
  PRESETS = [
    { label: "callba finds callbacks only inside a word",
      text: "In order to use the available callbacks, you need to register them.", query: "callba" },
    { label: "validate meets validations only through a stem",
      text: "Validations are used to ensure that only valid data is saved into your database.", query: "validate" },
    { label: "has_many is also the two words has and many",
      text: "A model that has many of something declares the association with has_many.", query: "has_many" },
    { label: "N+1 is two tokens or five",
      text: "Eager loading avoids the N+1 queries problem.", query: "N+1" },
    { label: "a sentence without spaces",
      text: "コールバックはレコードの保存の前後に呼ばれます。", query: "保存" }
  ].freeze

  Outcome = Struct.new(:strategy, :document_tokens, :query_tokens, :highlight, :error) do
    def match? = highlight.present?
  end

  attr_reader :text, :query

  def initialize(text:, query:)
    @text = text.to_s.strip
    @query = query.to_s.strip
  end

  def filled? = text.present? && query.present?

  # The query as Active Search hands it to FTS5 (its SQLite adapter's own rule: a plain word
  # passes through, anything else is quoted as a phrase), so the playground answers what the
  # search page would. The method is private in the gem and this is the one place that needs it.
  def fts_query
    @fts_query ||= ActiveSearch::StoreAdapters::Sqlite.new.send(:sanitize_fts_query, query)
  end

  def outcomes
    @outcomes ||= filled? ? SearchStrategy.all.map { |strategy| outcome(strategy) } : []
  end

  private
    # FTS5 refuses some queries that sanitizing cannot help with, the way the search page's
    # columns do; the other two tokenizers still answer.
    def outcome(strategy)
      document_tokens, highlight = Fts5Tokenizer.tokens_and_highlight(text, fts_query, tokenize: strategy.tokenize)
      Outcome.new(strategy, document_tokens, strategy.tokens(query), highlight, nil)
    rescue ActiveRecord::StatementInvalid => e
      Outcome.new(strategy, [], [], nil, e.message)
    end
end
