require "test_helper"

module RailsGuides
  class SectionSplitterTest < ActiveSupport::TestCase
    GUIDE = <<~MARKDOWN
      **DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

      Active Record Basics
      ====================

      This guide is an introduction to Active Record.

      --------------------------------------------------------------------------------

      What is Active Record?
      ----------------------

      Active Record is the M in [MVC](https://en.wikipedia.org/wiki/MVC) - the model -
      which wraps across two source lines.

      NOTE: Read about the [Active Record pattern][pattern] and [`find`][] too.

      [pattern]: https://www.martinfowler.com/eaaCatalog/activeRecord.html
      [`find`]:
          https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find

      ### The Active Record Pattern

      Here is *emphasis*, __strong text__ and `inline_code` kept.

      ```ruby
      class Product < ApplicationRecord
      end
      ```

      #### A Deeper Heading

      Text under the fourth-level heading.

      ### Empty Section

      ## Does it work!

      | Column | Type    |
      | ------ | ------- |
      | `id`   | integer |

      ### Using `find_by`

      Found it.

      ### Options (and Defaults): Overview

      Covered.

      ### Empty Too
    MARKDOWN

    setup do
      @result = SectionSplitter.call(GUIDE)
      @sections = @result[:sections].to_h { |section| [ section[:anchor], section ] }
    end

    test "takes the guide title from the setext H1 in the header" do
      assert_equal "Active Record Basics", @result[:title]
    end

    test "makes one document per H2 with no parent" do
      section = @sections.fetch("what-is-active-record-questionmark")

      assert_equal "What is Active Record?", section[:title]
      assert_nil section[:parent]
    end

    test "makes one document per H3 whose parent is the enclosing H2 title" do
      section = @sections.fetch("the-active-record-pattern")

      assert_equal "The Active Record Pattern", section[:title]
      assert_equal "What is Active Record?", section[:parent]
    end

    test "ends an H2 document where its first H3 begins" do
      assert_not_includes @sections.fetch("what-is-active-record-questionmark")[:body], "emphasis"
    end

    test "folds fourth-level headings into the enclosing document as a line of text" do
      body = @sections.fetch("the-active-record-pattern")[:body]

      assert_includes body, "\n\nA Deeper Heading\n\nText under the fourth-level heading."
      assert_nil @sections["a-deeper-heading"]
    end

    test "drops fenced code blocks" do
      assert_not_includes @sections.fetch("the-active-record-pattern")[:body], "ApplicationRecord"
    end

    test "keeps inline code without the backticks and strips emphasis markers" do
      assert_equal "Here is emphasis, strong text and inline_code kept.",
                   @sections.fetch("the-active-record-pattern")[:body].lines.first.chomp
    end

    test "keeps the text of links and drops their targets and definitions" do
      body = @sections.fetch("what-is-active-record-questionmark")[:body]

      assert_includes body, "the M in MVC - the model"
      assert_includes body, "Read about the Active Record pattern and find too."
      assert_not_includes body, "martinfowler"
      assert_not_includes body, "api.rubyonrails.org"
    end

    test "joins the lines of a wrapped paragraph and separates paragraphs with one blank line" do
      assert_equal "Active Record is the M in MVC - the model - which wraps across two source lines.\n\n" \
                   "Read about the Active Record pattern and find too.",
                   @sections.fetch("what-is-active-record-questionmark")[:body]
    end

    test "drops the NOTE label but keeps its sentence" do
      body = @sections.fetch("what-is-active-record-questionmark")[:body]

      assert_not_includes body, "NOTE"
      assert_includes body, "\n\nRead about"
    end

    test "reduces a table to its cell text" do
      assert_equal "Column Type\nid integer", @sections.fetch("does-it-work-bang")[:body]
    end

    test "skips headings whose body is empty" do
      assert_nil @sections["empty-section"]
      assert_nil @sections["empty-too"]
      assert_equal 5, @sections.size
    end

    test "anchors a question mark as -questionmark" do
      assert @sections.key?("what-is-active-record-questionmark")
    end

    test "anchors an exclamation mark as -bang" do
      assert_equal "Does it work!", @sections.fetch("does-it-work-bang")[:title]
    end

    test "anchors inline code in a heading by its text" do
      assert_equal "Using find_by", @sections.fetch("using-find-by")[:title]
    end

    test "drops colons and parentheses from anchors" do
      assert_equal "Options (and Defaults): Overview", @sections.fetch("options-and-defaults-overview")[:title]
    end

    test "prefixes repeated anchors with the parent's anchor like guides.rubyonrails.org" do
      markdown = <<~MARKDOWN
        Title
        =====

        --------------------------------------------------------------------------------

        Writing
        -------

        ### Options

        Options for writing.

        Reading
        -------

        ### Options

        Options for reading.
      MARKDOWN

      anchors = SectionSplitter.call(markdown)[:sections].map { |section| section[:anchor] }

      assert_equal [ "writing-options", "reading-options" ], anchors
    end
  end
end
