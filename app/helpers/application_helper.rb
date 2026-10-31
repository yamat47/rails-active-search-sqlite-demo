module ApplicationHelper
  # A token for the eye: a space inside a trigram is drawn as ␣, or "ns " and "s r" read as two
  # characters and a mystery.
  def visible_token(token) = token.tr(" ", "␣")

  def token_chip(token) = tag.span(visible_token(token), class: "token")

  # A trigram makes a token of nearly every character, and a paragraph of them says nothing a
  # sentence of them does not.
  TOKEN_CHIP_LIMIT = 60

  # A list of token chips, or +empty+ when there is none, cut off at TOKEN_CHIP_LIMIT with a count
  # of the rest.
  def token_chips(tokens, empty:)
    return tag.em(empty) if tokens.empty?

    chips = tokens.first(TOKEN_CHIP_LIMIT).map { |token| token_chip(token) }
    if tokens.size > TOKEN_CHIP_LIMIT
      chips << tag.span("and #{number_with_delimiter(tokens.size - TOKEN_CHIP_LIMIT)} more", class: "tokens-more")
    end
    safe_join(chips)
  end
end
