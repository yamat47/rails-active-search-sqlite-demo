# Shows how an FTS5 tokenizer splits a piece of text, by running it through a throwaway table.
#
# SQLite exposes no function that tokenizes a string, but the fts5vocab "instance" table lists
# every token of every row with its offset, so a one-row temporary table answers the question. The
# tables live in the temp schema and are dropped at the end, so nothing is left in the database.
module Fts5Tokenizer
  TABLE = "temp.fts5_tokenizer_preview"
  VOCAB = "temp.fts5_tokenizer_preview_vocab"

  def self.tokens(text, tokenize:)
    return [] if text.blank?

    connection = ActiveRecord::Base.connection
    connection.transaction do
      connection.execute("CREATE VIRTUAL TABLE #{TABLE} USING fts5(body, tokenize='#{tokenize}')")
      connection.execute("INSERT INTO #{TABLE}(body) VALUES (#{connection.quote(text)})")
      connection.execute("CREATE VIRTUAL TABLE #{VOCAB} USING fts5vocab('temp', 'fts5_tokenizer_preview', 'instance')")
      connection.select_values("SELECT term FROM #{VOCAB} ORDER BY offset")
    ensure
      connection.execute("DROP TABLE IF EXISTS #{VOCAB}")
      connection.execute("DROP TABLE IF EXISTS #{TABLE}")
    end
  end
end
