require "test_helper"

class TokenizersControllerTest < ActionDispatch::IntegrationTest
  setup do
    guide = Guide.create!(slug: "active_record_callbacks", title: "Active Record Callbacks",
      url: "https://guides.rubyonrails.org/v8.1/active_record_callbacks.html",
      source: "https://github.com/rails/rails/blob/v8.1.4/guides/source/active_record_callbacks.md")
    guide.sections.create!(position: 1, anchor: "callback-registration", title: "Callback Registration",
      body: "In order to use the available callbacks, you need to register them.")
    guide.sections.create!(position: 2, anchor: "validations", title: "Validations",
      body: "A callback runs before the validation.")
  end

  test "the page draws one sentence cut three ways, a card and a bar per tokenizer" do
    get tokenizers_path
    assert_response :success
    assert_select ".cuts-track[data-tokenizer=unicode61] .cuts-piece", text: "has"
    assert_select ".cuts-track[data-tokenizer=porter] .cuts-piece-reshaped", text: "mani"
    assert_select ".cuts-track[data-tokenizer=trigram] .cuts-piece", text: "ns␣"
    assert_select ".strategy#porter .migration code", text: SearchStrategy.find("porter").migration_line
    assert_select ".comparison-row", count: TokenizerComparison::SAMPLES.size
    assert_select ".comparison-row:first-child .comparison-bar.strategy-porter .comparison-count", text: "2"
    assert_select ".comparison-row:first-child .comparison-bar.strategy-unicode61 .comparison-count", text: "1"
  end

  test "the playground answers for both inputs, as FTS5 does under each tokenizer" do
    get tokenizers_path(text: "In order to use the available callbacks, you need to register them.", q: "callba")
    assert_response :success
    assert_select "#outcome-unicode61 .verdict-miss"
    assert_select "#outcome-porter .verdict-miss"
    assert_select "#outcome-trigram .verdict-hit"
    assert_select "#outcome-trigram .outcome-text mark", text: "callba"
    assert_select "#outcome-trigram .tokens .token", text: "cal"
    assert_select ".playground-fts code", text: "callba"
  end

  test "the playground tells when Active Search quotes the query, and escapes the text" do
    get tokenizers_path(text: "<b>N+1</b> queries", q: "N+1")
    assert_select ".playground-fts code", text: '"N+1"'
    assert_select "#outcome-unicode61 .verdict-hit"
    assert_select "#outcome-unicode61 .outcome-text", text: "<b>N+1</b> queries"
    assert_select "#outcome-unicode61 .outcome-text mark", text: "N+1"
  end

  test "the playground alone answers a Turbo Frame request" do
    get tokenizers_path(text: "callbacks", q: "callbacks"), headers: { "Turbo-Frame" => "playground-results" }
    assert_response :success
    assert_select "turbo-frame#playground-results .verdict-hit", count: 3
    assert_select ".cuts", count: 0
  end

  test "without both inputs the playground waits" do
    get tokenizers_path(q: "callbacks")
    assert_select ".playground-input[name=q][value=callbacks]"
    assert_select ".playground-empty"
    assert_select ".outcome", count: 0
  end
end
