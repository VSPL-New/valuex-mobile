/// What a suggestion stands for: a listing title, or a category to browse.
enum SuggestionType {
  listing('LISTING'),
  category('CATEGORY');

  final String apiValue;

  const SuggestionType(this.apiValue);

  static SuggestionType? fromApi(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

/// One auto-complete entry of `GET /search/suggestions`.
class SearchSuggestion {
  final String text;
  final SuggestionType type;

  /// Set for a category suggestion only.
  final String? categoryCode;

  const SearchSuggestion({required this.text, required this.type, this.categoryCode});

  bool get isCategory => type == SuggestionType.category;

  /// Null for an entry this app cannot show (no text, or a type it does not know yet).
  static SearchSuggestion? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final text = json['text'];
    final type = SuggestionType.fromApi(json['type'] as String?);
    if (text is! String || text.trim().isEmpty || type == null) return null;
    final code = json['categoryCode'];
    return SearchSuggestion(
      text: text,
      type: type,
      categoryCode: code is String && code.isNotEmpty ? code : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchSuggestion &&
      other.text == text &&
      other.type == type &&
      other.categoryCode == categoryCode;

  @override
  int get hashCode => Object.hash(text, type, categoryCode);
}
