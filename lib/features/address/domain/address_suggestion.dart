/// One line of the address search results.
class AddressSuggestion {
  final String placeId;
  final String primaryText;
  final String secondaryText;

  const AddressSuggestion({
    required this.placeId,
    required this.primaryText,
    this.secondaryText = '',
  });

  /// What a screen reader hears for the suggestion.
  String get fullText => secondaryText.isEmpty ? primaryText : '$primaryText, $secondaryText';
}
