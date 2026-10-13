require "test_helper"

class TinySegmenterTest < ActiveSupport::TestCase
  test "splits a Japanese sentence into words" do
    assert_equal %w[今晩 は ！ 良い 天気 です ね 。], TinySegmenter.segment("今晩は！良い天気ですね。")
  end

  test "keeps the spaces the text already has, so Ruby on Rails stays three words" do
    assert_equal %w[Ruby on Rails と SQLite], TinySegmenter.segment("Ruby on Rails と SQLite")
  end

  test "ignores leading ideographic spaces" do
    assert_equal %w[渋谷 の カフェ], TinySegmenter.segment("　渋谷のカフェ")
  end

  test "wakati joins the words with single spaces" do
    assert_equal "東京 都 渋谷 区", TinySegmenter.wakati("東京都渋谷区")
    assert_equal "", TinySegmenter.wakati(nil)
  end
end
