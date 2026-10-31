# Shows how an FTS5 tokenizer splits a piece of text, and where a query matches it, by running
# the text through a throwaway table.
#
# SQLite exposes no function that tokenizes a string, but the fts5vocab "instance" table lists
# every token of every row with its offset, so a one-row temporary table answers the question,
# and highlight() over the same table shows what a MATCH finds. The tables live in the temp
# schema and are dropped at the end, so nothing is left in the database.
module Fts5Tokenizer
  NAME = "fts5_tokenizer_preview"
  TABLE = "temp.#{NAME}"
  VOCAB = "temp.#{NAME}_vocab"

  def self.tokens(text, tokenize:)
    return [] if text.blank?

    with_table(text, tokenize:) { |connection| select_tokens(connection) }
  end

  # The tokens of +text+ and, when +fts_query+ (an FTS5 MATCH expression) matches it, the text
  # with each match between Active Search's own highlight markers, which its Highlighting module
  # renders; nil when it does not match. One table for both, since the playground wants both.
  def self.tokens_and_highlight(text, fts_query, tokenize:)
    return [ [], nil ] if text.blank?

    with_table(text, tokenize:) do |connection|
      highlight = fts_query.present? && connection.select_value(<<~SQL)
        SELECT highlight(#{NAME}, 0, #{connection.quote(ActiveSearch::Highlighting::STORE_OPEN_MARKER)},
                         #{connection.quote(ActiveSearch::Highlighting::STORE_CLOSE_MARKER)})
        FROM #{TABLE} WHERE #{NAME} MATCH #{connection.quote(fts_query)}
      SQL
      [ select_tokens(connection), highlight.presence ]
    end
  end

  def self.select_tokens(connection)
    connection.execute("CREATE VIRTUAL TABLE #{VOCAB} USING fts5vocab('temp', '#{NAME}', 'instance')")
    connection.select_values("SELECT term FROM #{VOCAB} ORDER BY offset")
  ensure
    connection.execute("DROP TABLE IF EXISTS #{VOCAB}")
  end

  def self.with_table(text, tokenize:)
    connection = ActiveRecord::Base.connection
    connection.transaction do
      connection.execute("CREATE VIRTUAL TABLE #{TABLE} USING fts5(body, tokenize='#{tokenize}')")
      connection.execute("INSERT INTO #{TABLE}(body) VALUES (#{connection.quote(text)})")
      yield connection
    ensure
      connection.execute("DROP TABLE IF EXISTS #{TABLE}")
    end
  end
  private_class_method :select_tokens, :with_table
end
