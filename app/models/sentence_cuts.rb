# Where each token of a sentence sits in it, for the figure on the explanation page that draws
# the three tokenizers' cuts under one line of text.
#
# FTS5 reports a token's position in tokens, not characters (see Fts5Tokenizer), so the character
# positions are recovered here: a unicode61 word is found in the lowercased sentence, in order; a
# porter stem sits where the word it came from does; a trigram is the three characters at its
# index. That holds for the ASCII sentence the page uses, which is all this is for.
class SentenceCuts
  # +word+ is set for a porter stem: the unicode61 word it was cut from.
  Piece = Struct.new(:start, :length, :token, :word) do
    # Whether the stem is simply the word with its tail removed, or reshaped ("many" is "mani").
    def trimmed? = word.start_with?(token)
  end

  attr_reader :sentence

  def initialize(sentence)
    @sentence = sentence
  end

  def pieces(strategy)
    case strategy.tokenize
    when "unicode61" then words
    when "porter" then stems
    when "trigram" then trigrams
    end
  end

  private
    def words
      @words ||= begin
        from = 0
        Fts5Tokenizer.tokens(sentence, tokenize: "unicode61").map do |word|
          start = sentence.downcase.index(word, from) or raise ArgumentError, "#{word.inspect} is not in #{sentence.inspect}"
          from = start + word.length
          Piece.new(start, word.length, word, nil)
        end
      end
    end

    def stems
      words.zip(Fts5Tokenizer.tokens(sentence, tokenize: "porter")).map do |piece, stem|
        Piece.new(piece.start, piece.length, stem, piece.token)
      end
    end

    def trigrams
      Fts5Tokenizer.tokens(sentence, tokenize: "trigram").each_with_index.map do |token, index|
        Piece.new(index, 3, token, nil)
      end
    end
end
