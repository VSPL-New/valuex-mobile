import 'category.dart';

class SchemaOption {
  final String code;
  final String label;

  const SchemaOption({required this.code, required this.label});

  factory SchemaOption.fromJson(Map<String, dynamic> json) =>
      SchemaOption(code: json['code'] as String, label: json['label'] as String);
}

/// The field becomes required when [key] holds one of [values] (price by transaction intent).
class RequiredWhen {
  final String key;
  final List<String> values;

  const RequiredWhen({required this.key, required this.values});

  factory RequiredWhen.fromJson(Map<String, dynamic> json) => RequiredWhen(
        key: json['key'] as String,
        values: [for (final value in json['values'] as List<dynamic>) value as String],
      );
}

/// The value types the server sends; option types without options arrive as TEXT or TEXT_LIST.
enum FieldType {
  text,
  longText,
  integer,
  decimal,
  boolean,
  date,
  option,
  multiOption,
  optionOrText,
  textList,
  object,
  json;

  static FieldType parse(String value) => switch (value) {
        'LONG_TEXT' => FieldType.longText,
        'INTEGER' => FieldType.integer,
        'DECIMAL' => FieldType.decimal,
        'BOOLEAN' => FieldType.boolean,
        'DATE' => FieldType.date,
        'OPTION' => FieldType.option,
        'MULTI_OPTION' => FieldType.multiOption,
        'OPTION_OR_TEXT' => FieldType.optionOrText,
        'TEXT_LIST' => FieldType.textList,
        'OBJECT' => FieldType.object,
        'JSON' => FieldType.json,
        _ => FieldType.text,
      };

  bool get isNumber => this == FieldType.integer || this == FieldType.decimal;
}

/// One category-specific question on the Item Details page.
class SchemaField {
  static const String sectionMore = 'MORE';

  final String key;
  final String label;
  final FieldType type;
  final String? unit;
  final bool required;
  final RequiredWhen? requiredWhen;
  final String section;
  final List<SchemaOption> options;
  final Map<String, dynamic> validation;
  final bool aiPrefill;

  /// An option that repeats the category name, so the seller is not asked twice.
  final String? prefillOption;

  const SchemaField({
    required this.key,
    required this.label,
    required this.type,
    this.unit,
    this.required = false,
    this.requiredWhen,
    this.section = 'CATEGORY',
    this.options = const [],
    this.validation = const {},
    this.aiPrefill = false,
    this.prefillOption,
  });

  factory SchemaField.fromJson(Map<String, dynamic> json) => SchemaField(
        key: json['key'] as String,
        label: json['label'] as String,
        type: FieldType.parse(json['type'] as String),
        unit: json['unit'] as String?,
        required: json['required'] as bool? ?? false,
        requiredWhen: json['requiredWhen'] == null
            ? null
            : RequiredWhen.fromJson(json['requiredWhen'] as Map<String, dynamic>),
        section: json['section'] as String? ?? 'CATEGORY',
        options: [
          for (final option in json['options'] as List<dynamic>? ?? const [])
            SchemaOption.fromJson(option as Map<String, dynamic>),
        ],
        validation: Map<String, dynamic>.from(json['validation'] as Map? ?? const {}),
        aiPrefill: json['aiPrefill'] as bool? ?? false,
        prefillOption: json['prefillOption'] as String?,
      );

  num? get min => validation['min'] as num?;
  num? get max => validation['max'] as num?;
  int? get maxLength => (validation['maxLength'] as num?)?.toInt();
  int? get maxItems => (validation['maxItems'] as num?)?.toInt();
  int? get maxDecimals => (validation['maxDecimals'] as num?)?.toInt();
  String? get pattern => validation['pattern'] as String?;

  bool get isMore => section == sectionMore;
}

/// Which common listing fields the form shows; a shown field is also required.
class CommonFields {
  final bool conditionVisible;
  final bool quantityVisible;
  final bool negotiableVisible;

  /// Real Estate: the price comes from the field that matches the transaction intent.
  final bool priceDerived;

  const CommonFields({
    this.conditionVisible = true,
    this.quantityVisible = true,
    this.negotiableVisible = true,
    this.priceDerived = false,
  });

  factory CommonFields.fromJson(Map<String, dynamic> json) => CommonFields(
        conditionVisible: json['conditionVisible'] as bool? ?? true,
        quantityVisible: json['quantityVisible'] as bool? ?? true,
        negotiableVisible: json['negotiableVisible'] as bool? ?? true,
        priceDerived: json['priceDerived'] as bool? ?? false,
      );
}

/// The Item Details form for one L3 category (GET /categories/{code}/listing-schema).
class ListingSchema {
  static const String transactionIntentKey = 'transaction_intent';

  final CategoryRef category;
  final String profileCode;
  final String group;
  final CommonFields common;
  final List<String> transactionIntents;
  final List<SchemaField> fields;

  const ListingSchema({
    required this.category,
    required this.profileCode,
    required this.group,
    required this.common,
    this.transactionIntents = const [],
    this.fields = const [],
  });

  factory ListingSchema.fromJson(Map<String, dynamic> json) => ListingSchema(
        category: CategoryRef.fromJson(json['category'] as Map<String, dynamic>),
        profileCode: json['profileCode'] as String,
        group: json['group'] as String,
        common: CommonFields.fromJson(json['common'] as Map<String, dynamic>),
        transactionIntents: [
          for (final intent in json['transactionIntents'] as List<dynamic>? ?? const [])
            intent as String,
        ],
        fields: [
          for (final field in json['fields'] as List<dynamic>)
            SchemaField.fromJson(field as Map<String, dynamic>),
        ],
      );

  bool get isRealEstate => group == 'REAL_ESTATE';

  Set<String> get keys => {for (final field in fields) field.key};

  SchemaField? field(String key) {
    for (final field in fields) {
      if (field.key == key) return field;
    }
    return null;
  }

  /// Required fields first, then the other fields of the category.
  List<SchemaField> get categoryFields => [
        for (final f in fields)
          if (!f.isMore) f
      ];

  List<SchemaField> get moreFields => [
        for (final f in fields)
          if (f.isMore) f
      ];

  /// A field is asked when it is required outright, or when another field's value calls for it.
  bool isRequired(SchemaField field, Map<String, Object?> attributes) {
    if (field.required) return true;
    final when = field.requiredWhen;
    return when != null && when.values.contains(attributes[when.key]);
  }

  /// Keys the seller has not filled, or filled with something the server would refuse.
  List<String> invalidKeys(Map<String, Object?> attributes) => [
        for (final field in fields)
          if (_problem(field, attributes)) field.key,
      ];

  bool _problem(SchemaField field, Map<String, Object?> attributes) {
    final value = attributes[field.key];
    if (isBlankValue(value)) return isRequired(field, attributes);
    return !isValidValue(field, value);
  }
}

bool isBlankValue(Object? value) =>
    value == null ||
    (value is String && value.trim().isEmpty) ||
    (value is Iterable && value.isEmpty) ||
    (value is Map && value.isEmpty);

/// The same limits the server checks, so most mistakes are caught before sending.
bool isValidValue(SchemaField field, Object? value) {
  switch (field.type) {
    case FieldType.integer:
    case FieldType.decimal:
      final number = value is num ? value : num.tryParse('$value'.replaceAll(',', ''));
      if (number == null) return false;
      if (field.type == FieldType.integer && number != number.truncate()) return false;
      final places = field.maxDecimals;
      if (field.type == FieldType.decimal && places != null) {
        final text = number.toString();
        final dot = text.indexOf('.');
        if (dot >= 0 && text.length - dot - 1 > places) return false;
      }
      return (field.min == null || number >= field.min!) &&
          (field.max == null || number <= field.max!);
    case FieldType.text:
    case FieldType.longText:
    case FieldType.optionOrText:
      final text = '$value'.trim();
      final limit = field.maxLength;
      if (limit != null && text.length > limit) return false;
      final pattern = field.pattern;
      return pattern == null || RegExp(pattern).hasMatch(text);
    default:
      return true;
  }
}
