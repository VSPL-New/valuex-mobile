import 'dart:convert';

import 'listing_schema.dart';

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

/// Limits from US-114 and US-006; the server checks the same rules.
class ListingDetailsRules {
  ListingDetailsRules._();

  static const int maxTitle = 100;
  static const int maxDescription = 2000;
  static const int maxConditionNotes = 1000;
  static const int maxPriceRupees = 100000000;
  static const int maxPriceDecimals = 2;
  static const int minQuantity = 1;
  static const int maxQuantity = 1000;
}

/// The common fields of the Item Details page. Category-specific fields are tracked by key.
enum DetailsField {
  title,
  category,
  condition,
  conditionNotes,
  description,
  price,
  negotiable,
  quantity
}

/// What the seller has entered so far.
class ListingDetailsDraft {
  final String title;
  final String? categoryCode;
  final ListingCondition? condition;
  final String conditionNotes;
  final String description;

  /// As typed, without the rupee sign; parsed when validated.
  final String price;
  final bool? negotiable;

  /// As typed; goods only.
  final String quantity;

  /// Category-specific values by attribute key: text, option codes, numbers (as typed), booleans,
  /// ISO dates, lists and maps.
  final Map<String, Object?> attributes;

  const ListingDetailsDraft({
    this.title = '',
    this.categoryCode,
    this.condition,
    this.conditionNotes = '',
    this.description = '',
    this.price = '',
    this.negotiable,
    this.quantity = '1',
    this.attributes = const {},
  });

  ListingDetailsDraft copyWith({
    String? title,
    String? categoryCode,
    ListingCondition? condition,
    String? conditionNotes,
    String? description,
    String? price,
    bool? negotiable,
    String? quantity,
    Map<String, Object?>? attributes,
  }) {
    return ListingDetailsDraft(
      title: title ?? this.title,
      categoryCode: categoryCode ?? this.categoryCode,
      condition: condition ?? this.condition,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      description: description ?? this.description,
      price: price ?? this.price,
      negotiable: negotiable ?? this.negotiable,
      quantity: quantity ?? this.quantity,
      attributes: attributes ?? this.attributes,
    );
  }

  /// Common fields that are missing or invalid, in page order. Without a schema only the fields
  /// every category has are checked.
  List<DetailsField> invalidFields(ListingSchema? schema) {
    final common = schema?.common;
    return [
      if (title.trim().isEmpty || title.trim().length > ListingDetailsRules.maxTitle)
        DetailsField.title,
      if (categoryCode == null || categoryCode!.isEmpty) DetailsField.category,
      if (common?.conditionVisible ?? false) ...[
        if (condition == null) DetailsField.condition,
        if (conditionNotes.trim().isEmpty ||
            conditionNotes.trim().length > ListingDetailsRules.maxConditionNotes)
          DetailsField.conditionNotes,
      ],
      if (description.trim().isEmpty ||
          description.trim().length > ListingDetailsRules.maxDescription)
        DetailsField.description,
      if (schema != null && !common!.priceDerived && parsedPrice == null) DetailsField.price,
      if ((common?.negotiableVisible ?? false) && negotiable == null) DetailsField.negotiable,
      if ((common?.quantityVisible ?? false) && parsedQuantity == null) DetailsField.quantity,
    ];
  }

  /// Category-specific keys that are missing or invalid.
  List<String> invalidAttributes(ListingSchema? schema) =>
      schema == null ? const [] : schema.invalidKeys(attributes);

  /// Ready to save: the form for the category is loaded and everything it asks is filled.
  bool isValid(ListingSchema? schema) =>
      schema != null && invalidFields(schema).isEmpty && invalidAttributes(schema).isEmpty;

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

  int? get parsedQuantity {
    final value = int.tryParse(quantity.trim());
    if (value == null ||
        value < ListingDetailsRules.minQuantity ||
        value > ListingDetailsRules.maxQuantity) {
      return null;
    }
    return value;
  }

  /// The values to send: only keys the category asks, numbers as numbers, blanks left out.
  Map<String, Object?> attributePayload(ListingSchema schema) {
    final payload = <String, Object?>{};
    for (final field in schema.fields) {
      final value = attributes[field.key];
      if (isBlankValue(value)) continue;
      payload[field.key] = field.type.isNumber && value is String
          ? num.parse(value.trim().replaceAll(',', ''))
          : value is String
              ? value.trim()
              : value;
    }
    return payload;
  }

  /// The PATCH body: only what the category's form shows.
  Map<String, Object?> toJson(ListingSchema schema, {String? city}) {
    final common = schema.common;
    return {
      'title': title.trim(),
      if (common.conditionVisible) 'condition': condition?.apiValue,
      if (common.conditionVisible) 'conditionNotes': conditionNotes.trim(),
      'description': description.trim(),
      if (!common.priceDerived) 'price': parsedPrice,
      if (common.negotiableVisible) 'negotiable': negotiable,
      if (common.quantityVisible) 'quantity': parsedQuantity,
      'attributes': attributePayload(schema),
      'location': city,
    };
  }
}

/// A suggestion AI made for the page (US-005). Absent while AI is off, which is the default.
class AiSuggestion {
  final String id;
  final String? categoryCode;
  final String? title;
  final ListingCondition? condition;
  final String? conditionNotes;
  final String? description;

  /// Category-specific values read from the photos, by attribute key, in the shape the form uses.
  final Map<String, Object?> attributes;

  /// Keys AI was less sure about; the seller is asked to check these.
  final Set<String> verifyKeys;

  const AiSuggestion({
    required this.id,
    this.categoryCode,
    this.title,
    this.condition,
    this.conditionNotes,
    this.description,
    this.attributes = const {},
    this.verifyKeys = const {},
  });

  /// Reads the answer of POST /listings/{id}/ai-suggestions. Null when the answer carries no
  /// suggestion: AI was not available (`fallback`) or it has no id to report feedback against.
  static AiSuggestion? fromJson(Map<String, dynamic> json) {
    final id = json['suggestionId'] as String?;
    if (id == null || json['fallback'] == true) return null;
    final categories = json['categorySuggestions'] as List<dynamic>? ?? const [];
    final attributes = <String, Object?>{};
    final verify = <String>{};
    for (final item in json['attributeSuggestions'] as List<dynamic>? ?? const []) {
      final map = item as Map<String, dynamic>;
      final key = map['key'] as String?;
      if (key == null || isBlankValue(map['value'])) continue;
      attributes[key] = map['value'];
      if (map['verify'] == true) verify.add(key);
    }
    return AiSuggestion(
      id: id,
      categoryCode: categories.isEmpty
          ? null
          : (categories.first as Map<String, dynamic>)['categoryCode'] as String?,
      title: json['titleSuggestion'] as String?,
      condition: ListingCondition.fromApi(json['conditionSuggestion'] as String?),
      conditionNotes: json['conditionNotesSuggestion'] as String?,
      description: json['descriptionSuggestion'] as String?,
      attributes: attributes,
      verifyKeys: verify,
    );
  }

  /// True when AI recognised nothing it could fill in.
  bool get isEmpty =>
      categoryCode == null &&
      (title ?? '').trim().isEmpty &&
      (description ?? '').trim().isEmpty &&
      attributes.isEmpty;

  /// The page values before the seller touches anything.
  ListingDetailsDraft get asDraft => ListingDetailsDraft(
        title: _clip(title, ListingDetailsRules.maxTitle),
        categoryCode: categoryCode,
        condition: condition,
        conditionNotes: _clip(conditionNotes, ListingDetailsRules.maxConditionNotes),
        description: _clip(description, ListingDetailsRules.maxDescription),
        attributes: attributes,
      );

  static String _clip(String? text, int max) {
    final value = text?.trim() ?? '';
    return value.length > max ? value.substring(0, max) : value;
  }
}

enum SuggestionAction { accepted, edited, rejected }

/// What the seller did with one suggested field; [attributeKey] names the attribute when [field]
/// is `ATTRIBUTE`.
class SuggestionFeedback {
  final String field;
  final String? attributeKey;
  final SuggestionAction action;
  final String? originalValue;
  final String? finalValue;

  const SuggestionFeedback({
    required this.field,
    this.attributeKey,
    required this.action,
    this.originalValue,
    this.finalValue,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        if (attributeKey != null) 'attributeKey': attributeKey,
        'action': action.name.toUpperCase(),
        'originalValue': originalValue,
        'finalValue': finalValue,
      };
}

/// Accepted when unchanged, edited when changed, rejected when cleared; fields AI did not
/// suggest are left out.
List<SuggestionFeedback> suggestionFeedback(AiSuggestion suggestion, ListingDetailsDraft current) {
  SuggestionFeedback? one(String field, String? original, String? now, {String? attributeKey}) {
    if (original == null || original.trim().isEmpty) return null;
    final finalValue = (now == null || now.trim().isEmpty) ? null : now.trim();
    final action = finalValue == null
        ? SuggestionAction.rejected
        : finalValue == original.trim()
            ? SuggestionAction.accepted
            : SuggestionAction.edited;
    return SuggestionFeedback(
      field: field,
      attributeKey: attributeKey,
      action: action,
      originalValue: original.trim(),
      finalValue: finalValue,
    );
  }

  return [
    one('CATEGORY', suggestion.categoryCode, current.categoryCode),
    one('TITLE', suggestion.title, current.title),
    one('CONDITION', suggestion.condition?.apiValue, current.condition?.apiValue),
    one('CONDITION_NOTES', suggestion.conditionNotes, current.conditionNotes),
    one('DESCRIPTION', suggestion.description, current.description),
    for (final entry in suggestion.attributes.entries)
      one(
        'ATTRIBUTE',
        _asText(entry.value),
        _asText(current.attributes[entry.key]),
        attributeKey: entry.key,
      ),
  ].whereType<SuggestionFeedback>().toList();
}

String? _asText(Object? value) {
  if (value == null) return null;
  return value is String ? value : (value is num || value is bool ? '$value' : jsonEncode(value));
}
