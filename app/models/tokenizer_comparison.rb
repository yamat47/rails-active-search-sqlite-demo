# How many sections each tokenizer finds for one query, and how many of them all three find, for
# the explanation page's bars. Counted when the page renders, so the numbers follow the corpus.
class TokenizerComparison
  # The same queries the search page suggests, each with the gap it shows.
  SAMPLES = [
    [ "callbacks", "porter also finds the sections that only say \"callback\"" ],
    [ "validate", "porter stems it to valid, as it does validation, validations and valid" ],
    [ "deprecat", "not a word, so only a substring match can find deprecated and deprecation" ],
    [ "has_many", "unicode61 and porter read it as the phrase \"has many\", which prose contains too" ],
    [ "N+1", "the same, as the phrase \"n 1\"; trigram wants the three characters together" ]
  ].freeze

  # The most the SQLite adapter pages to, and more than the corpus has sections, so every hit's
  # id comes back.
  LIMIT = 10_000

  attr_reader :query, :why

  def self.samples = SAMPLES.map { |query, why| new(query, why) }

  def initialize(query, why)
    @query = query
    @why = why
  end

  def count(strategy) = ids.fetch(strategy).size

  # Sections every tokenizer finds.
  def shared = @shared ||= ids.values.reduce(:&).size

  def max = ids.values.map(&:size).max

  private
    def ids
      @ids ||= SearchStrategy.all.index_with { |strategy| strategy.ids(query, limit: LIMIT) }
    end
end
