/// A suggestion split for display: the part the user already typed, then the rest.
typedef SuggestionParts = ({String typed, String rest});

/// Splits [text] at the end of the typed [query] when the text starts with it, ignoring case and
/// surrounding spaces of the query; otherwise nothing counts as typed.
SuggestionParts splitTypedPrefix(String text, String query) {
  final typed = query.trim();
  if (typed.isEmpty || typed.length > text.length) return (typed: '', rest: text);
  final head = text.substring(0, typed.length);
  if (head.toLowerCase() != typed.toLowerCase()) return (typed: '', rest: text);
  return (typed: head, rest: text.substring(typed.length));
}
