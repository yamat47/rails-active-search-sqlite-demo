require "cgi/escape"

module RailsGuides
  # Splits the Markdown source of a Rails guide into plain-text documents, one per H2
  # and one per H3 heading, keyed by the anchors guides.rubyonrails.org gives them.
  #
  # The anchor algorithm mirrors `dom_id` in rails/rails guides/rails_guides/markdown.rb,
  # including the way a repeated heading text gets its parent's anchor as a prefix, so
  # "<guide url>#<anchor>" always lands on the right heading of the live page.
  class SectionSplitter
    Document = Struct.new(:node, :parent, :tokens)

    # The guide renderer treats everything before the first line of 40+ hyphens as the
    # header (title and introduction); only headings after it get anchors.
    HEADER_SEPARATOR = /^-{40,}$/
    FENCE = /\A[ \t]*(`{3,}|~{3,})/
    # Redcarpet strips trailing hashes from an ATX heading even without a space before them.
    ATX_HEADING = /\A(\#{1,6})[ \t]+(.*?)[ \t]*\#*[ \t]*\z/
    SETEXT_H1_UNDERLINE = /\A=+[ \t]*\z/
    SETEXT_H2_UNDERLINE = /\A-+[ \t]*\z/
    LIST_ITEM = /\A[ \t]*(?:[-*+]|\d+\.)[ \t]+/
    TABLE_ROW = /\A[ \t]*\|/
    TABLE_SEPARATOR = /\A[ \t]*\|?(?:[ \t]*:?-+:?[ \t]*\|)*[ \t]*:?-+:?[ \t]*\|?[ \t]*\z/
    CELL_SEPARATOR = /(?<!\\)\|/
    BLOCKQUOTE = /\A[ \t]*>[ \t]?/
    # The guides put `[name]: url` definitions right after the paragraph that uses them,
    # usually with the URL alone on the next line, so they turn up mid-section rather
    # than at the end of the file. A label may hold a code span such as `errors[]`.
    REFERENCE_DEFINITION = /\A {0,3}\[(?:[^\[\]]|\[[^\[\]]*\])+\]:(?<target>.*)\z/
    # Matched after inline markup is gone so that a label written as **NOTE**: goes too.
    NOTE_LABEL = /\A\s*(?:TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)[.:][ \t]*/
    # Zero-width characters are invisible on the page and only get in the way of matching.
    INVISIBLE = /[​-‍⁠﻿]/
    HTML_COMMENT = /<!--.*?-->/m
    # Code spans and backslash escapes are matched in a single pass so that a backslash
    # inside code stays literal and an escaped backtick does not open a span.
    PROTECTED = /(`+)(.+?)\1|\\([\\`*_{}\[\]()#+\-.!:|&<>^~"'])/
    AUTOLINK = /<((?:https?|ftp|mailto):[^\s<>]+)>/
    IMAGE = /!\[[^\]]*\](?:\((?:[^()]|\([^()]*\))*\)|\[[^\]]*\])/
    LINK = /\[([^\[\]]*)\](?:\((?:[^()]|\([^()]*\))*\)|\[[^\]]*\])/
    HTML_TAG = %r{</?([a-zA-Z][^<>]*)>}
    LINE_BREAK_TAG = /\Abr\b/i
    STRONG = /(\*\*|__)(?=\S)(.+?)(?<=\S)\1/
    EMPHASIS = /(?<![\w*])\*(?=[^\s*])(.+?)(?<=[^\s*])\*(?![\w*])|(?<![\w_])_(?=[^\s_])(.+?)(?<=[^\s_])_(?![\w_])/
    STRIKETHROUGH = /~~(?=\S)(.+?)(?<=\S)~~/
    PLACEHOLDER = /\u0000(\d+)\u0000/
    ANCHOR_PUNCTUATION = /[#{Regexp.escape('\\/`*_{}[]()#+-.!:,;|&<>^~=\'"')}]+/

    def self.call(markdown)
      new(markdown).call
    end

    def initialize(markdown)
      @markdown = markdown
      @node_ids = {}
    end

    def call
      header, separator, body = @markdown.partition(HEADER_SEPARATOR)
      header, body = "", header if separator.empty?
      header_tokens = tokenize(header)
      body_tokens = tokenize(body)

      { title: title_from(header_tokens) || title_from(body_tokens), sections: sections_from(body_tokens) }
    end

    private

    # Turns the source into [:heading, level, text], [:line, text] and [:blank] tokens
    # with fenced code already removed, so later stages never see a fence.
    def tokenize(text)
      tokens = []
      fence = nil

      text.each_line(chomp: true) do |line|
        if (match = FENCE.match(line))
          marker = match[1]
          if fence.nil?
            fence = marker
          elsif marker[0] == fence[0] && marker.size >= fence.size
            fence = nil
          end
          next
        end
        next if fence

        if (match = ATX_HEADING.match(line))
          tokens << [ :heading, match[1].size, match[2] ]
        elsif SETEXT_H1_UNDERLINE.match?(line) && paragraph_line?(tokens.last)
          tokens << [ :heading, 1, tokens.pop[1] ]
        elsif SETEXT_H2_UNDERLINE.match?(line) && paragraph_line?(tokens.last)
          tokens << [ :heading, 2, tokens.pop[1] ]
        elsif line.strip.empty?
          tokens << [ :blank ]
        else
          tokens << [ :line, line ]
        end
      end

      tokens
    end

    # A setext underline only promotes the line right above it, and only when that line
    # is prose; under a list item or table row a dash line is a rule.
    def paragraph_line?(token)
      return false unless token&.first == :line

      line = token[1]
      !LIST_ITEM.match?(line) && !TABLE_ROW.match?(line) && !BLOCKQUOTE.match?(line)
    end

    def title_from(tokens)
      heading = tokens.find { |token| token.first == :heading && token[1] == 1 }
      plain_text(heading[2]) if heading
    end

    def sections_from(tokens)
      documents = []
      hierarchy = []
      current = nil

      tokens.each do |token|
        unless token.first == :heading
          current&.tokens&.push(token)
          next
        end

        level, text = token[1], plain_text(token[2])
        node = nil
        # Anchors are assigned to h2..h5 in document order, and a later duplicate can
        # rename an earlier heading, so every level has to go through dom_id even
        # though only h2 and h3 become documents.
        if (2..5).cover?(level)
          node = { text: text, id: nil }
          hierarchy = hierarchy.first(level - 2) + [ node ]
          node[:id] = dom_id(hierarchy)
        end

        case level
        when 2
          documents << (current = Document.new(node, nil, []))
        when 3
          documents << (current = Document.new(node, hierarchy[-2]&.fetch(:text), []))
        else
          current&.tokens&.push([ :blank ], [ :plain, text ], [ :blank ])
        end
      end

      documents.filter_map do |document|
        body = render(document.tokens)
        next if body.empty?

        { anchor: document.node[:id], title: document.node[:text], parent: document.parent, body: body }
      end
    end

    def render(tokens)
      blocks = tokens.chunk { |token| token.first == :blank }.filter_map { |blank, group| group unless blank }
      blocks.map { |block| render_block(block) }.reject(&:empty?).join("\n\n")
    end

    # A block is the text between two blank lines. It is usually one paragraph, but a
    # list or table may follow a paragraph without a blank line in between, so a block
    # is cut into segments: a paragraph becomes one line, a list or table one line per
    # item or row.
    def render_block(tokens)
      segments = []
      skip_definition_target = false

      tokens.each do |kind, text|
        if kind == :plain
          segments << [ :plain, [ text ] ]
          next
        end

        line = text.sub(BLOCKQUOTE, "")
        if skip_definition_target
          skip_definition_target = false
          next
        elsif (definition = REFERENCE_DEFINITION.match(line))
          skip_definition_target = definition[:target].strip.empty?
          next
        end

        if TABLE_ROW.match?(line)
          append_segment(segments, :table, line)
        elsif (match = LIST_ITEM.match(line))
          append_segment(segments, :list, match.post_match)
        elsif segments.last&.first == :list
          segments.last[1][-1] = "#{segments.last[1][-1]} #{line}"
        elsif segments.last&.first == :paragraph
          segments.last[1][-1] = "#{segments.last[1][-1]} #{line}"
        else
          append_segment(segments, :paragraph, line)
        end
      end

      segments.flat_map { |kind, items| render_segment(kind, items) }
              .map { |line| line.gsub(INVISIBLE, "").gsub(/\s+/, " ").strip }
              .reject(&:empty?)
              .join("\n")
    end

    def append_segment(segments, kind, item)
      segments << [ kind, [] ] unless segments.last&.first == kind
      segments.last[1] << item
    end

    def render_segment(kind, items)
      case kind
      when :paragraph, :list
        items.map { |item| plain_text(item).sub(NOTE_LABEL, "") }
      when :table
        items.filter_map { |row| plain_text(table_cells(row).join(" ")) unless TABLE_SEPARATOR.match?(row) }
      else
        items
      end
    end

    def table_cells(row)
      row.strip.delete_prefix("|").delete_suffix("|").split(CELL_SEPARATOR).map(&:strip).reject(&:empty?)
    end

    # Reduces inline Markdown to the text a reader sees. Code spans are restored last so
    # that nothing inside them is mistaken for a tag, a link or emphasis.
    def plain_text(text)
      protected_runs = []
      text = text.gsub(PROTECTED) do
        protected_runs << ($2 ? $2.strip : $3)
        "\u0000#{protected_runs.size - 1}\u0000"
      end

      text = text.gsub(HTML_COMMENT, "")
                 .gsub(AUTOLINK, '\1')
                 .gsub(IMAGE, "")
                 .gsub(LINK, '\1')
                 .gsub(HTML_TAG) { LINE_BREAK_TAG.match?($1) ? " " : "" }
                 .gsub(STRONG, '\2')
                 .gsub(EMPHASIS) { $1 || $2 }
                 .gsub(STRIKETHROUGH, '\1')

      CGI.unescapeHTML(text).gsub(PLACEHOLDER) { protected_runs[$1.to_i] }
    end

    # Port of RailsGuides::Markdown#dom_id. `nodes` is the heading's ancestry from its
    # h2 down to itself; a repeated anchor is disambiguated with the parent's anchor,
    # and the earlier of two nested duplicates is renamed retroactively.
    def dom_id(nodes)
      id = dom_id_text(nodes.last[:text])

      if (earlier = @node_ids[id])
        if earlier.size > 1
          @node_ids.delete(id)
          earlier.last[:id] = dom_id_with_parent_node(id, earlier[-2])
          @node_ids[earlier.last[:id]] = earlier
        end
        id = dom_id_with_parent_node(id, nodes[-2])
      end

      @node_ids[id] = nodes
      id
    end

    def dom_id_text(text)
      text.downcase
          .gsub("?", "-questionmark")
          .gsub("!", "-bang")
          .gsub("[]", "-squarebrackets")
          .gsub(ANCHOR_PUNCTUATION, " ").strip
          .gsub(/\s+/, "-")
    end

    def dom_id_with_parent_node(id, parent)
      parent ? "#{parent[:id]}-#{id}" : id
    end
  end
end
