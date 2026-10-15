require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    guide = Guide.create!(slug: "active_record_callbacks", title: "Active Record Callbacks",
      url: "https://guides.rubyonrails.org/v8.1/active_record_callbacks.html",
      source: "https://github.com/rails/rails/blob/v8.1.4/guides/source/active_record_callbacks.md")
    guide.sections.create!(position: 1, anchor: "callback-registration", title: "Callback Registration",
      body: "In order to use the available callbacks, you need to register them.")
    @other = Guide.create!(slug: "other", title: "Other", url: "https://example.invalid/other.html", source: "https://example.invalid/other.md")
  end

  test "the front page without a query explains the three columns" do
    get root_path
    assert_response :success
    assert_select ".intro"
    assert_select ".column", count: 0
  end

  test "the form keeps the URL to the query: no commit value, empty fields dropped on submit" do
    get root_path
    assert_select "form.search-form[data-controller=clean-params][data-action='submit->clean-params#submit']"
    assert_select "form.search-form input[type=submit]:not([name])"
    assert_select "script[type='importmap']"
  end

  test "a query renders one column per strategy with the hits it has" do
    get root_path(q: "callba")
    assert_response :success
    assert_select "#strategy-unicode61 .column-count", text: "0 hits"
    assert_select "#strategy-porter .column-count", text: "0 hits"
    assert_select "#strategy-trigram .hit-title mark", text: "Callba"
    assert_select "#strategy-trigram .hit-link[href=?]", "https://guides.rubyonrails.org/v8.1/active_record_callbacks.html#callback-registration"
    assert_select "#strategy-trigram .token", text: "cal"
  end

  test "a guide filter narrows every column" do
    get root_path(q: "callbacks", guide: @other.id)
    assert_select "#strategy-porter .column-count", text: "0 hits"
  end
end
