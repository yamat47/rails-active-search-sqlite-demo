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

  # Wrapped around each match by .highlight: control characters, so they cannot occur in the text.
  OPEN_MARKER = "\u0001"
  CLOSE_MARKER = "\u0002"

  def self.tokens(text, tokenize:)
    return [] if text.blank?

    with_table(text, tokenize:) do |connection|
      connection.execute("CREATE VIRTUAL TABLE #{VOCAB} USING fts5vocab('temp', '#{NAME}', 'instance')")
      connection.select_values("SELECT term FROM #{VOCAB} ORDER BY offset")
    ensure
      connection.execute("DROP TABLE IF EXISTS #{VOCAB}")
    end
  end

  # +text+ with every match of +fts_query+, an FTS5 MATCH expression, between OPEN_MARKER and
  # CLOSE_MARKER, or nil when the text does not match at all.
  def self.highlight(text, fts_query, tokenize:)
    return nil if text.blank? || fts_query.blank?

    with_table(text, tokenize:) do |connection|
      connection.select_value(<<~SQL)
        SELECT highlight(#{NAME}, 0, #{connection.quote(OPEN_MARKER)}, #{connection.quote(CLOSE_MARKER)})
        FROM #{TABLE} WHERE #{NAME} MATCH #{connection.quote(fts_query)}
      SQL
    end
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
  private_class_method :with_table
end
