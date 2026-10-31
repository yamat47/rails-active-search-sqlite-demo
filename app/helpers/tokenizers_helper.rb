module TokenizersHelper
  # A token as a chip. A space inside a trigram is drawn as ␣, or "ns " and "s r" read as two
  # characters and a mystery.
  def token_chip(token, css_class: "token")
    tag.span(token.tr(" ", "␣"), class: css_class)
  end

  # A list of token chips, cut off after +limit+ with a count of the rest: a trigram makes a token
  # of nearly every character, and a paragraph of them says nothing a sentence of them does not.
  def token_chips(tokens, limit: 60)
    chips = tokens.first(limit).map { |token| token_chip(token) }
    chips << tag.span("and #{number_with_delimiter(tokens.size - limit)} more", class: "tokens-more") if tokens.size > limit
    safe_join(chips)
  end

  # The playground's highlighted document: Fts5Tokenizer's markers become <mark>, after the text
  # itself is escaped, so the document can say anything.
  def playground_highlight(text)
    ERB::Util.html_escape(text)
      .gsub(Fts5Tokenizer::OPEN_MARKER, "<mark>")
      .gsub(Fts5Tokenizer::CLOSE_MARKER, "</mark>")
      .html_safe # rubocop:disable Rails/OutputSafety
  end
end
