# frozen_string_literal: true

require_relative "tiny_segmenter/model"

# Splits Japanese text into words. A port of TinySegmenter
# (http://chasen.org/~taku/software/TinySegmenter/, (c) 2008 Taku Kudo, BSD licence), following
# the Ruby port by Peter Graham (https://github.com/6/tiny_segmenter, BSD) with the API reduced
# to what the demo calls.
#
# A character-level model of a few thousand weights rather than a dictionary: no native extension,
# so it runs the same under ruby.wasm as on the server, which is why the demo uses it over MeCab.
# The original author quotes about 95% accuracy, and the mistakes are part of what the demo shows.
class TinySegmenter
  BIAS = -332

  CHARACTER_TYPES = [
    [ /[一二三四五六七八九十百千万億兆]/, "M" ],
    [ /[一-龠々〆ヵヶ]/, "H" ],
    [ /[ぁ-ん]/, "I" ],
    [ /[ァ-ヴーｱ-ﾝﾞｰ]/, "K" ],
    [ /[a-zA-Zａ-ｚＡ-Ｚ]/, "A" ],
    [ /[0-9０-９]/, "N" ]
  ].freeze

  class << self
    def segment(text) = instance.segment(text)

    # The words joined with spaces, which is what FTS5's unicode61 tokenizer splits on.
    def wakati(text) = segment(text).join(" ")

    private

    def instance = @instance ||= new
  end

  # Text that already has spaces in it is split there first; the original dropped them, which
  # fused "Ruby on Rails" into one word.
  def segment(text)
    text.to_s.split(/[[:space:]　]+/).flat_map { |chunk| segment_chunk(chunk) }
  end

  private

  def segment_chunk(text)
    return [] if text.empty?

    chars = text.each_char.to_a
    segments = %w[B3 B2 B1] + chars + %w[E1 E2 E3]
    types = %w[O O O] + chars.map { |char| character_type(char) } + %w[O O O]

    words = []
    word = segments[3]
    p1, p2, p3 = %w[U U U]

    (4..segments.size - 4).each do |i|
      score = BIAS + sum_scores(p1, p2, p3, segments[i - 3, 6], types[i - 3, 6])
      mark = "O"
      if score > 0
        words << word
        word = ""
        mark = "B"
      end
      p1, p2, p3 = p2, p3, mark
      word += segments[i]
    end
    words << word unless word.empty?
    words
  end

  def character_type(char)
    CHARACTER_TYPES.each { |pattern, type| return type if char.match?(pattern) }
    "O"
  end

  def sum_scores(p1, p2, p3, (w1, w2, w3, w4, w5, w6), (c1, c2, c3, c4, c5, c6))
    m = Model
    m.score(:UP1, p1) + m.score(:UP2, p2) + m.score(:UP3, p3) +
      m.score(:BP1, p1 + p2) + m.score(:BP2, p2 + p3) +
      m.score(:UW1, w1) + m.score(:UW2, w2) + m.score(:UW3, w3) +
      m.score(:UW4, w4) + m.score(:UW5, w5) + m.score(:UW6, w6) +
      m.score(:BW1, w2 + w3) + m.score(:BW2, w3 + w4) + m.score(:BW3, w4 + w5) +
      m.score(:TW1, w1 + w2 + w3) + m.score(:TW2, w2 + w3 + w4) +
      m.score(:TW3, w3 + w4 + w5) + m.score(:TW4, w4 + w5 + w6) +
      m.score(:UC1, c1) + m.score(:UC2, c2) + m.score(:UC3, c3) +
      m.score(:UC4, c4) + m.score(:UC5, c5) + m.score(:UC6, c6) +
      m.score(:BC1, c2 + c3) + m.score(:BC2, c3 + c4) + m.score(:BC3, c4 + c5) +
      m.score(:TC1, c1 + c2 + c3) + m.score(:TC2, c2 + c3 + c4) +
      m.score(:TC3, c3 + c4 + c5) + m.score(:TC4, c4 + c5 + c6) +
      m.score(:UQ1, p1 + c1) + m.score(:UQ2, p2 + c2) + m.score(:UQ3, p3 + c3) +
      m.score(:BQ1, p2 + c2 + c3) + m.score(:BQ2, p2 + c3 + c4) +
      m.score(:BQ3, p3 + c2 + c3) + m.score(:BQ4, p3 + c3 + c4) +
      m.score(:TQ1, p2 + c1 + c2 + c3) + m.score(:TQ2, p2 + c2 + c3 + c4) +
      m.score(:TQ3, p3 + c1 + c2 + c3) + m.score(:TQ4, p3 + c2 + c3 + c4)
  end
end
