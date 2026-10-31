# The explanation page: why the three columns of the search page differ, with a playground.
class TokenizersController < ApplicationController
  # A sentence the page cuts three ways: a plural, an identifier with an underscore and a full stop,
  # which is where the tokenizers part company.
  SENTENCE = "Validations run before has_many callbacks."

  def show
    @playground = TokenizerPlayground.new(text: params[:text], query: params[:q])
    # The playground re-renders alone as the reader types; the rest of the page costs fifteen searches.
    return render :playground if turbo_frame_request?

    @cuts = SentenceCuts.new(SENTENCE)
    @comparisons = TokenizerComparison.samples
  end
end
