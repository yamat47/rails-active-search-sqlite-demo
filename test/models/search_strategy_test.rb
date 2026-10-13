require "test_helper"

class SearchStrategyTest < ActiveSupport::TestCase
  def strategy(key) = SearchStrategy.all.find { |s| s.key == key }

  test "unicode61 keeps a Japanese sentence as one token and splits at ASCII spaces" do
    assert_equal [ "東京都渋谷区神宮前の店舗" ], strategy("unicode61").tokens("東京都渋谷区神宮前の店舗")
    assert_equal [ "ruby", "on", "rails" ], strategy("unicode61").tokens("Ruby on Rails")
  end

  test "trigram emits every three characters" do
    assert_equal [ "渋谷区", "谷区神", "区神宮" ], strategy("trigram").tokens("渋谷区神宮")
    assert_empty strategy("trigram").tokens("渋谷")
  end

  test "the segmented strategy tokenizes the words TinySegmenter produced" do
    assert_equal [ "渋谷", "区", "神宮", "前" ], strategy("segmented").tokens("渋谷区神宮前")
    assert_equal "渋谷 区", strategy("segmented").query_text("渋谷区")
  end

  test "an empty query has no tokens and leaves no table behind" do
    assert_empty strategy("trigram").tokens("")
    strategy("trigram").tokens("渋谷区")
    assert_nil ActiveRecord::Base.connection.select_value("SELECT name FROM sqlite_temp_master WHERE name LIKE 'fts5_tokenizer_preview%'")
  end

  test "display_highlight closes the gaps TinySegmenter opened, around mark tags too" do
    html = "東京 都 <mark>渋谷</mark> 区 の Ruby on Rails".html_safe
    assert_equal "東京都<mark>渋谷</mark>区の Ruby on Rails", strategy("segmented").display_highlight(html)
    assert_equal html, strategy("trigram").display_highlight(html)
  end
end
