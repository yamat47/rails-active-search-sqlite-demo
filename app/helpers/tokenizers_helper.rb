module TokenizersHelper
  # The playground's highlighted document, rendered as Active Search renders a hit's highlight.
  def playground_highlight(text)
    ActiveSearch::Highlighting.escape_html(text, ActiveSearch::Highlighting::FieldOptions.new)
  end
end
