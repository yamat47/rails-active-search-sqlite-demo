module Aozora
  # Turns the raw text of an Aozora Bunko work into plain paragraphs for full-text search.
  #
  # Aozora's text files carry markup meant for readers and typesetters: ruby in 《》,
  # ｜ marking where a ruby run begins, editorial notes in ［＃…］, and a legend block
  # fenced by hyphen lines that explains those symbols. None of it helps search, so
  # only the prose is kept. The footer that starts at 底本： is preserved verbatim
  # because Aozora asks that the source edition and volunteer credits travel with
  # the text.
  class TextCleaner
    FENCE = /\A-{10,}\z/
    COLOPHON_START = /\A底本[：:]/
    # Shift_JIS cannot encode every character, so Aozora prints ※ and a note giving
    # the JIS X 0213 面区点 code (or a UCS code point) of the intended character.
    GAIJI_NOTE = /※［＃([^［］]*)］/
    # \b is useless here: Onigmo treats the kanji before the code as word characters.
    MENKUTEN = /(?<!\d)[12]-\d{1,2}-\d{1,2}(?!\d)/
    UCS = /U\+(\h{4,6})(?!\h)/
    # Only the 面区点 codes that occur in the bundled works are mapped; the values
    # were decoded through Ruby's EUC-JIS-2004 transcoder. Notes with any other
    # code are dropped and reported through `unmapped_gaiji`.
    GAIJI = {
      "1-14-75" => "匀",
      "1-84-66" => "戢",
      "1-87-71" => "犍",
      "1-88-81" => "眶",
      "1-88-85" => "睜",
      "1-91-48" => "虢",
      "1-92-44" => "軺",
      "2-1-79" => "傪",
      "2-4-33" => "嘷",
      "2-12-93" => "扭",
      "2-79-45" => "𤄃"
    }.freeze
    # Notes nest when a gaiji sits inside an emphasised span, so the innermost one
    # has to go first; excluding brackets from the match guarantees that.
    NOTE = /［＃[^［］]*］/
    RUBY = /《[^》]*》/
    RUBY_START = "｜"
    # [[:space:]] covers the full-width space (U+3000) that String#strip leaves alone.
    EDGE_SPACE = /\A[[:space:]]+|[[:space:]]+\z/
    TRANSLATOR = /訳\z/
    # Chapter numerals and headings are shorter than this; sentences worth indexing are not.
    MIN_PARAGRAPH_LENGTH = 8
    # Section dividers such as a run of dashes pass the length check yet say nothing.
    WORD_CHARACTER = /[[:alnum:]]/

    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @lines = text.delete_prefix("﻿").each_line(chomp: true).to_a
      @unmapped_gaiji = []
    end

    def call
      preamble, rest = split_preamble(@lines)
      body, colophon = split_colophon(drop_legend(rest))

      {
        title: scrub(preamble.first.to_s),
        author: author_from(preamble),
        paragraphs: body.filter_map { |line| paragraph_from(line) },
        colophon: colophon.join("\n").rstrip,
        unmapped_gaiji: @unmapped_gaiji.uniq
      }
    end

    private

    def split_preamble(lines)
      preamble = lines.take_while { |line| !blank?(line) && !FENCE.match?(line) }
      [ preamble, lines.drop(preamble.size) ]
    end

    # The preamble is title, optional subtitle, author, optional translator. The
    # translator is the only line we can recognise, so drop it and take the last line.
    def author_from(preamble)
      candidates = preamble.drop(1).map { |line| scrub(line) }.reject { |line| TRANSLATOR.match?(line) }
      candidates.last.to_s
    end

    def drop_legend(lines)
      opening = lines.index { |line| !blank?(line) }
      return lines if opening.nil? || !FENCE.match?(lines[opening])

      after_opening = lines.drop(opening + 1)
      closing = after_opening.index { |line| FENCE.match?(line) }
      closing ? after_opening.drop(closing + 1) : after_opening
    end

    def split_colophon(lines)
      start = lines.index { |line| COLOPHON_START.match?(line) }
      start ? [ lines.take(start), lines.drop(start) ] : [ lines, [] ]
    end

    def paragraph_from(line)
      text = scrub(line)
      text if text.length >= MIN_PARAGRAPH_LENGTH && text.match?(WORD_CHARACTER)
    end

    def scrub(line)
      text = restore_gaiji(line)
      text = text.gsub(NOTE, "") while NOTE.match?(text)
      text.gsub(RUBY, "").delete(RUBY_START).gsub(EDGE_SPACE, "")
    end

    def restore_gaiji(line)
      line.gsub(GAIJI_NOTE) do
        note = Regexp.last_match(1)
        gaiji_for(note) || (@unmapped_gaiji << note; "")
      end
    end

    def gaiji_for(note)
      if (code = note[MENKUTEN])
        GAIJI[code]
      elsif (code_point = note[UCS, 1])
        code_point.hex.chr(Encoding::UTF_8)
      end
    end

    def blank?(line)
      line.match?(/\A[[:space:]]*\z/)
    end
  end
end
