require "test_helper"

class SentenceCutsTest < ActiveSupport::TestCase
  setup { @cuts = SentenceCuts.new("Validations run before has_many callbacks.") }

  test "a word sits where it is in the sentence, lowercased" do
    pieces = @cuts.pieces(SearchStrategy.find("unicode61"))
    assert_equal %w[validations run before has many callbacks], pieces.map(&:token)
    assert_equal [ 0, 12, 16, 23, 27, 32 ], pieces.map(&:start)
    assert_equal [ 11, 3, 6, 3, 4, 9 ], pieces.map(&:length)
  end

  test "a stem keeps its word's place and knows whether it is a prefix of it" do
    pieces = @cuts.pieces(SearchStrategy.find("porter"))
    valid, many = pieces.values_at(0, 4)
    assert_equal [ "valid", "validations", 0, 11, true ], [ valid.token, valid.word, valid.start, valid.length, valid.trimmed? ]
    assert_equal [ "mani", "many", 27, 4, false ], [ many.token, many.word, many.start, many.length, many.trimmed? ]
  end

  test "a trigram is the three characters at its index, spaces included" do
    pieces = @cuts.pieces(SearchStrategy.find("trigram"))
    assert_equal @cuts.sentence.length - 2, pieces.size
    assert_equal [ "val", 0, 3 ], [ pieces[0].token, pieces[0].start, pieces[0].length ]
    assert_equal [ "ns ", 9 ], [ pieces[9].token, pieces[9].start ]
  end
end
