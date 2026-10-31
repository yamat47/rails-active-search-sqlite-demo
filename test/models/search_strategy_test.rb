require "test_helper"

class SearchStrategyTest < ActiveSupport::TestCase
  def strategy(key) = SearchStrategy.find(key)

  test "an unknown tokenizer key raises rather than answering nil" do
    assert_raises(ArgumentError) { SearchStrategy.find("nope") }
  end

  test "unicode61 lowercases and splits on punctuation, underscores included" do
    assert_equal [ "has", "many", "and", "belongs", "to" ], strategy("unicode61").tokens("has_many and belongs_to")
    assert_equal [ "n", "1", "queries" ], strategy("unicode61").tokens("N+1 queries")
  end

  test "porter reduces words to their stems" do
    assert_equal [ "valid", "valid", "valid" ], strategy("porter").tokens("validate validation validations")
    assert_equal [ "callback" ], strategy("porter").tokens("callbacks")
  end

  test "trigram emits every three characters and nothing for a shorter query" do
    assert_equal [ "cal", "all", "llb", "lba" ], strategy("trigram").tokens("callba")
    assert_empty strategy("trigram").tokens("ca")
  end

  test "an empty query has no tokens and leaves no table behind" do
    assert_empty strategy("trigram").tokens("")
    strategy("trigram").tokens("callbacks")
    assert_nil ActiveRecord::Base.connection.select_value("SELECT name FROM sqlite_temp_master WHERE name LIKE 'fts5_tokenizer_preview%'")
  end
end
