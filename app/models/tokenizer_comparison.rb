# How many sections each tokenizer finds for one query, and how many of them all three find, for
# the explanation page's bars. Counted from the corpus rather than written down, so the numbers
# follow it; cached until the sections change, since a page load would otherwise run every
# sample query three times.
class TokenizerComparison
  # The queries the search page suggests, each with the gap between the tokenizers it shows.
  SAMPLES = [
    [ "callbacks", "porter also finds the sections that only say \"callback\"" ],
    [ "validate", "porter stems it to valid, as it does validation, validations and valid" ],
    [ "deprecat", "not a word, so only a substring match can find deprecated and deprecation" ],
    [ "has_many", "unicode61 and porter read it as the phrase \"has many\", which prose contains too" ],
    [ "N+1", "the same, as the phrase \"n 1\"; trigram wants the three characters together" ],
    [ "eager loading", "two words are a phrase for all three; porter also takes \"eager load\" and " \
                       "\"eager loaded\", and trigram the characters in a row, space included, whatever the word ends in" ]
  ].freeze

  attr_reader :query, :why

  def self.samples
    version = [ Section.count, Section.maximum(:updated_at) ]
    SAMPLES.map { |query, why| new(query, why, version:) }
  end

  def initialize(query, why, version: nil)
    @query = query
    @why = why
    @version = version
  end

  def count(strategy) = ids.fetch(strategy.key).size

  # Sections every tokenizer finds.
  def shared = @shared ||= ids.values.reduce(:&).size

  def max = @max ||= ids.values.map(&:size).max

  private
    # Keyed by the tokenizer's name rather than the SearchStrategy, which comes back from the
    # cache as a copy that is not the one in SearchStrategy.all.
    def ids
      @ids ||= Rails.cache.fetch([ "tokenizer_comparison", query, @version ]) do
        SearchStrategy.all.to_h { |strategy| [ strategy.key, strategy.ids(query) ] }
      end
    end
end
