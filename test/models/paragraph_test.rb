require "test_helper"

class ParagraphTest < ActiveSupport::TestCase
  setup do
    @work = Work.create!(title: "試し", author: "名無し", card_id: 1, card_url: "https://www.aozora.gr.jp/")
    [
      "東京都渋谷区神宮前の店舗で待ち合わせた。",
      "渋谷のカフェに行った。",
      "Ruby on Rails と SQLite の全文検索を試す。"
    ].each_with_index { |body, i| @work.paragraphs.create!(position: i + 1, body: body) }
  end

  test "saving a paragraph writes it to all three indexes inline" do
    assert_equal 3, ParagraphDocument.count
    assert_equal 3, TrigramParagraphDocument.count
    assert_equal 3, SegmentedParagraphDocument.count
  end

  test "the default index treats a run of Japanese as one token, so 渋谷区 inside a sentence is not found" do
    assert_equal 0, Paragraph.search("渋谷区").results.total
    assert_equal 1, Paragraph.search("Rails").results.total
  end

  test "the trigram index finds 渋谷区 inside a sentence but nothing for the two-character 渋谷" do
    assert_equal 1, Paragraph.search("渋谷区", index: :trigram_paragraphs).results.total
    assert_equal 0, Paragraph.search("渋谷", index: :trigram_paragraphs).results.total
  end

  test "the segmented index finds the two-character 渋谷 when the query is segmented the same way" do
    results = Paragraph.search(TinySegmenter.wakati("渋谷"), index: :segmented_paragraphs).results
    assert_equal 2, results.total
  end

  test "the segmented document holds the body split into words" do
    body = ActiveRecord::Base.connection.select_value(
      "SELECT body FROM segmented_paragraph_documents_fts WHERE body MATCH '\"カフェ\"'"
    )
    assert_equal "渋谷 の カフェ に 行っ た 。", body
  end

  test "a highlight wraps the match in mark tags" do
    paragraph = Paragraph.search("渋谷区", index: :trigram_paragraphs).highlight(body: true).results.first
    assert_equal "東京都<mark>渋谷区</mark>神宮前の店舗で待ち合わせた。", paragraph.hit.highlight(:body)
  end

  test "destroying a paragraph removes it from the indexes" do
    @work.paragraphs.find_by!(position: 2).destroy
    assert_equal 2, SegmentedParagraphDocument.count
    assert_equal 0, Paragraph.search(TinySegmenter.wakati("カフェ"), index: :segmented_paragraphs).results.total
  end
end
