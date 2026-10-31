require "test_helper"

class TokenizerPlaygroundTest < ActiveSupport::TestCase
  test "a plain word reaches FTS5 as it is, anything else as a phrase, like Active Search" do
    assert_equal "has_many", TokenizerPlayground.new(text: "x", query: "has_many").fts_query
    assert_equal '"N+1"', TokenizerPlayground.new(text: "x", query: "N+1").fts_query
    assert_equal "eager loading", TokenizerPlayground.new(text: "x", query: "eager loading").fts_query
  end

  test "porter alone matches a stem, trigram alone a substring, and all three the exact word" do
    text = "Validations are used to ensure that only valid data is saved."
    by_key = ->(query) { TokenizerPlayground.new(text:, query:).outcomes.to_h { |o| [ o.strategy.key, o.match? ] } }

    assert_equal({ "unicode61" => false, "porter" => true, "trigram" => false }, by_key.call("validate"))
    assert_equal({ "unicode61" => false, "porter" => false, "trigram" => true }, by_key.call("alidat"))
    assert_equal({ "unicode61" => true, "porter" => true, "trigram" => true }, by_key.call("saved"))
  end

  test "a query of two characters makes no trigram and matches nothing" do
    outcome = TokenizerPlayground.new(text: "callbacks", query: "ca").outcomes.last
    assert_equal "trigram", outcome.strategy.key
    assert_empty outcome.query_tokens
    assert_not outcome.match?
  end

  test "the highlight marks each match and leaves the rest of the text as it was" do
    outcome = TokenizerPlayground.new(text: "A callback runs before the callbacks.", query: "callback").outcomes.first
    assert_equal "A \uE000callback\uE001 runs before the callbacks.", outcome.highlight
  end

  test "a query FTS5 cannot use answers no hit on every tokenizer rather than raising" do
    outcomes = TokenizerPlayground.new(text: "callbacks", query: '"').outcomes
    assert_equal 3, outcomes.size
    outcomes.each { |outcome| assert_not outcome.match? }
  end
end
