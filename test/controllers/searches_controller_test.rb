require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    work = Work.create!(title: "試し", author: "名無し", card_id: 1, card_url: "https://www.aozora.gr.jp/")
    work.paragraphs.create!(position: 1, body: "東京都渋谷区神宮前の店舗で待ち合わせた。")
  end

  test "the front page without a query explains the three columns" do
    get root_path
    assert_response :success
    assert_select ".intro"
    assert_select ".column", count: 0
  end

  test "a query renders one column per strategy with the hits it has" do
    get root_path(q: "渋谷区")
    assert_response :success
    assert_select "#strategy-unicode61 .column-count", text: "0 hits"
    assert_select "#strategy-trigram .hit-body mark", text: "渋谷区"
    assert_select "#strategy-segmented .token", text: "渋谷"
  end

  test "an author filter narrows every column" do
    get root_path(q: "渋谷区", author: "別人")
    assert_select "#strategy-trigram .column-count", text: "0 hits"
  end

  test "a work page shows its paragraphs with anchors" do
    get work_path(Work.first)
    assert_response :success
    assert_select "p#p1", text: /渋谷区/
  end
end
