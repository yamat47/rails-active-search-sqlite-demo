require "test_helper"

class SectionTest < ActiveSupport::TestCase
  setup do
    @guide = Guide.create!(slug: "active_record_callbacks", title: "Active Record Callbacks",
      url: "https://guides.rubyonrails.org/v8.1/active_record_callbacks.html",
      source: "https://github.com/rails/rails/blob/v8.1.4/guides/source/active_record_callbacks.md")
    [
      [ "the-object-life-cycle", "The Object Life Cycle", "Callbacks allow you to trigger logic before or after an alteration of an object's state." ],
      [ "callback-registration", "Callback Registration", "In order to use a callback, you need to register it." ],
      [ "validations", "Validations", "Validations are used to ensure that only valid data is saved." ]
    ].each_with_index do |(anchor, title, body), i|
      @guide.sections.create!(position: i + 1, anchor: anchor, title: title, body: body)
    end
  end

  test "saving a section writes it to all three indexes inline" do
    assert_equal 3, SectionDocument.count
    assert_equal 3, PorterSectionDocument.count
    assert_equal 3, TrigramSectionDocument.count
  end

  test "the default index matches a word only as written, so callback and callbacks are different" do
    assert_equal 1, Section.search("callbacks").results.total
    assert_equal 1, Section.search("callback").results.total
  end

  test "the porter index folds the forms of a word together" do
    assert_equal 2, Section.search("callbacks", index: :porter_sections).results.total
    assert_equal 1, Section.search("validate", index: :porter_sections).results.total
    assert_equal 0, Section.search("validate").results.total
  end

  test "the trigram index matches inside a word and nothing for two characters" do
    assert_equal 2, Section.search("callba", index: :trigram_sections).results.total
    assert_equal 0, Section.search("callba").results.total
    assert_equal 0, Section.search("ca", index: :trigram_sections).results.total
  end

  test "a filter on the guide narrows the search" do
    other = Guide.create!(slug: "other", title: "Other", url: "https://example.invalid/other.html", source: "https://example.invalid/other.md")
    other.sections.create!(position: 1, anchor: "a", title: "Elsewhere", body: "Callbacks here too.")
    assert_equal 2, Section.search("callbacks").results.total
    assert_equal 1, Section.search("callbacks").filter(guide_id: @guide.id).results.total
  end

  test "a highlight wraps the match in mark tags and the title is highlighted too" do
    section = Section.search("registration").highlight(title: true, body: true).results.first
    assert_equal "Callback <mark>Registration</mark>", section.hit.highlight(:title)
    assert_nil section.hit.highlight(:body)
  end

  test "destroying a section removes it from the indexes" do
    @guide.sections.find_by!(anchor: "validations").destroy
    assert_equal 2, TrigramSectionDocument.count
    assert_equal 0, Section.search("validations", index: :porter_sections).results.total
  end

  test "a section knows its address on the guides site" do
    section = @guide.sections.first
    assert_equal "https://guides.rubyonrails.org/v8.1/active_record_callbacks.html#the-object-life-cycle", section.url
    assert_equal "The Object Life Cycle", section.breadcrumb
  end
end
