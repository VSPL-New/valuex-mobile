/// Item condition values the server accepts (US-114).
enum ListingCondition {
  brandNew('NEW'),
  likeNew('LIKE_NEW'),
  good('GOOD'),
  fair('FAIR'),
  poor('POOR');

  final String apiValue;

  const ListingCondition(this.apiValue);

  static ListingCondition? fromApi(String? value) {
    for (final condition in values) {
      if (condition.apiValue == value) return condition;
    }
    return null;
  }
}

/// Limits from US-114; the server checks the same rules.
class ListingDetailsRules {
  ListingDetailsRules._();

  static const int maxTitle = 100;
  static const int maxDescription = 2000;
  static const int maxPriceRupees = 10000000;
  static const int maxPriceDecimals = 2;
}

/// The required fields of the Item Details page.
enum DetailsField { title, category, condition, description, price }

/// What the seller has entered so far.
class ListingDetailsDraft {
  final String title;
  final String? categorySlug;
  final ListingCondition? condition;
  final String description;

  /// As typed, without the rupee sign; parsed when validated.
  final String price;

  const ListingDetailsDraft({
    this.title = '',
    this.categorySlug,
    this.condition,
    this.description = '',
    this.price = '',
  });

  ListingDetailsDraft copyWith({
    String? title,
    String? categorySlug,
    ListingCondition? condition,
    String? description,
    String? price,
  }) {
    return ListingDetailsDraft(
      title: title ?? this.title,
      categorySlug: categorySlug ?? this.categorySlug,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      price: price ?? this.price,
    );
  }

  /// Fields that are missing or invalid, in page order.
  List<DetailsField> get invalidFields => [
        if (title.trim().isEmpty || title.trim().length > ListingDetailsRules.maxTitle)
          DetailsField.title,
        if (categorySlug == null || categorySlug!.isEmpty) DetailsField.category,
        if (condition == null) DetailsField.condition,
        if (description.trim().isEmpty ||
            description.trim().length > ListingDetailsRules.maxDescription)
          DetailsField.description,
        if (parsedPrice == null) DetailsField.price,
      ];

  bool get isValid => invalidFields.isEmpty;

  /// The price in rupees, or null when it is empty, not a number, zero, over the limit or has
  /// more than two decimals.
  double? get parsedPrice {
    final text = price.trim().replaceAll(',', '');
    final match = RegExp(r'^\d+(\.\d{1,2})?$').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(text);
    if (value == null || value <= 0 || value > ListingDetailsRules.maxPriceRupees) return null;
    return value;
  }
}

/// A suggestion AI made for the page (US-005). Absent while AI is off, which is the default.
class AiSuggestion {
  final String id;
  final String? categorySlug;
  final String? title;
  final ListingCondition? condition;
  final String? description;

  const AiSuggestion({
    required this.id,
    this.categorySlug,
    this.title,
    this.condition,
    this.description,
  });

  /// The page values before the seller touches anything.
  ListingDetailsDraft get asDraft => ListingDetailsDraft(
        title: _clip(title, ListingDetailsRules.maxTitle),
        categorySlug: categorySlug,
        condition: condition,
        description: _clip(description, ListingDetailsRules.maxDescription),
      );

  static String _clip(String? text, int max) {
    final value = text?.trim() ?? '';
    return value.length > max ? value.substring(0, max) : value;
  }
}

enum SuggestionAction { accepted, edited, rejected }

/// What the seller did with one suggested field.
class SuggestionFeedback {
  final String field;
  final SuggestionAction action;
  final String? originalValue;
  final String? finalValue;

  const SuggestionFeedback({
    required this.field,
    required this.action,
    this.originalValue,
    this.finalValue,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'action': action.name.toUpperCase(),
        'originalValue': originalValue,
        'finalValue': finalValue,
      };
}

/// Accepted when unchanged, edited when changed, rejected when cleared; fields AI did not
/// suggest are left out.
List<SuggestionFeedback> suggestionFeedback(AiSuggestion suggestion, ListingDetailsDraft current) {
  SuggestionFeedback? one(String field, String? original, String? now) {
    if (original == null || original.trim().isEmpty) return null;
    final finalValue = (now == null || now.trim().isEmpty) ? null : now.trim();
    final action = finalValue == null
        ? SuggestionAction.rejected
        : finalValue == original.trim()
            ? SuggestionAction.accepted
            : SuggestionAction.edited;
    return SuggestionFeedback(
      field: field,
      action: action,
      originalValue: original.trim(),
      finalValue: finalValue,
    );
  }

  return [
    one('CATEGORY', suggestion.categorySlug, current.categorySlug),
    one('TITLE', suggestion.title, current.title),
    one('CONDITION', suggestion.condition?.apiValue, current.condition?.apiValue),
    one('DESCRIPTION', suggestion.description, current.description),
  ].whereType<SuggestionFeedback>().toList();
}
