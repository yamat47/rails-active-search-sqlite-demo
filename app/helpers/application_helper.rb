module ApplicationHelper
  # A token for the eye: a space inside a trigram is drawn as ␣, or "ns " and "s r" read as two
  # characters and a mystery.
  def visible_token(token) = token.tr(" ", "␣")

  def token_chip(token) = tag.span(visible_token(token), class: "token")

  # A list of token chips, or +empty+ when there is none. Cut off after sixty with a count of the
  # rest: a trigram makes a token of nearly every character, and a paragraph of them says nothing
  # a sentence of them does not.
  def token_chips(tokens, empty:)
    return tag.em(empty) if tokens.empty?

    chips = tokens.first(60).map { |token| token_chip(token) }
    chips << tag.span("and #{number_with_delimiter(tokens.size - 60)} more", class: "tokens-more") if tokens.size > 60
    safe_join(chips)
  end
end
