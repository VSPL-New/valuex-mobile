import '../../../core/utils/formatters.dart';
import 'listing_preview.dart';
import 'listing_schema.dart';

/// The words the preview adds around saved values; the caller supplies them in the seller's language.
class PreviewLabels {
  final String yes;
  final String no;
  final String notProvided;
  final String quantity;
  final String conditionNotes;

  /// Writes a saved date in the seller's language.
  final String Function(DateTime date) formatDate;

  const PreviewLabels({
    required this.yes,
    required this.no,
    required this.notProvided,
    required this.quantity,
    required this.conditionNotes,
    required this.formatDate,
  });
}

class PreviewRow {
  final String label;
  final String value;

  /// A mandatory field with no saved value: shown as "not provided", never filled in.
  final bool missing;

  const PreviewRow({required this.label, required this.value, this.missing = false});
}

/// The two tabs of the preview (US-123). Title, price, condition and city live in the summary above
/// the tabs, so they never appear here.
class PreviewFields {
  /// Every applicable mandatory field, in the category's order.
  final List<PreviewRow> overview;

  /// Every other populated field.
  final List<PreviewRow> details;

  /// The category's form is missing, so what is mandatory is not known.
  final bool schemaUnavailable;

  const PreviewFields({
    this.overview = const [],
    this.details = const [],
    this.schemaUnavailable = false,
  });
}

/// Splits the saved values by the category's own rules, whoever filled them in (seller, AI or a
/// correction of an AI suggestion): `required` and `requiredWhen` decide, not the form's "More
/// details" section. Blank optional values are left out; `0` and `false` are values.
PreviewFields projectPreviewFields(ListingPreviewData data, PreviewLabels labels) {
  final schema = data.schema;
  final notes = data.conditionNotes.trim();
  if (schema == null) {
    // Without the form nothing can be called mandatory, so the known common values go to Details.
    return PreviewFields(
      schemaUnavailable: true,
      details: [
        if (data.quantity != null) PreviewRow(label: labels.quantity, value: '${data.quantity}'),
        if (notes.isNotEmpty) PreviewRow(label: labels.conditionNotes, value: notes),
      ],
    );
  }

  final overview = <PreviewRow>[];
  final details = <PreviewRow>[];
  final attributes = data.attributes;

  if (schema.common.quantityVisible) {
    overview.add(_row(labels.quantity, data.quantity == null ? null : '${data.quantity}', labels));
  }
  if (schema.common.conditionVisible) {
    overview.add(_row(labels.conditionNotes, notes.isEmpty ? null : notes, labels));
  }

  for (final field in schema.fields) {
    if (_isDerivedPrice(schema, field, attributes)) continue;
    final value = attributes[field.key];
    final text = isBlankValue(value) ? '' : formatPreviewValue(field, value, labels);
    final mandatory = schema.isRequired(field, attributes);
    if (text.isEmpty) {
      if (mandatory) overview.add(_row(field.label, null, labels));
    } else {
      (mandatory ? overview : details).add(PreviewRow(label: field.label, value: text));
    }
  }

  final known = schema.keys;
  for (final entry in attributes.entries) {
    if (known.contains(entry.key) || isBlankValue(entry.value)) continue;
    final text = formatPreviewValue(null, entry.value, labels);
    if (text.isNotEmpty) details.add(PreviewRow(label: _humanKey(entry.key), value: text));
  }
  return PreviewFields(overview: overview, details: details);
}

PreviewRow _row(String label, String? value, PreviewLabels labels) => value == null
    ? PreviewRow(label: label, value: labels.notProvided, missing: true)
    : PreviewRow(label: label, value: value);

/// Real Estate: the summary already shows the price that matches the chosen intent, so only that
/// amount field is left out; any other amount (a deposit, a maintenance charge) stays.
bool _isDerivedPrice(ListingSchema schema, SchemaField field, Map<String, Object?> attributes) {
  final when = field.requiredWhen;
  return schema.common.priceDerived &&
      when != null &&
      when.key == ListingSchema.transactionIntentKey &&
      when.values.contains(attributes[when.key]);
}

/// A saved value in words: option codes become their labels, dates and numbers are formatted,
/// lists and objects are joined. The result is plain text.
String formatPreviewValue(SchemaField? field, Object? value, PreviewLabels labels) {
  if (value is bool) return value ? labels.yes : labels.no;
  if (value is num) return _number(field, value);
  if (value is List) {
    return [
      for (final item in value)
        if (!isBlankValue(item)) formatPreviewValue(field, item, labels),
    ].where((text) => text.isNotEmpty).join(', ');
  }
  if (value is Map) {
    return [
      for (final entry in value.entries)
        if (!isBlankValue(entry.value))
          '${_humanKey('${entry.key}')}: ${formatPreviewValue(null, entry.value, labels)}',
    ].join('; ');
  }
  final text = '$value'.trim();
  if (field == null) return text;
  switch (field.type) {
    case FieldType.date:
      final date = DateTime.tryParse(text);
      return date == null ? text : labels.formatDate(date);
    case FieldType.option:
    case FieldType.multiOption:
    case FieldType.optionOrText:
      for (final option in field.options) {
        if (option.code == text || option.label == text) return option.label;
      }
      return text;
    default:
      return text;
  }
}

String _number(SchemaField? field, num value) {
  final unit = field?.unit;
  if (unit == 'INR') return Formatters.money(value);
  final text = value == value.roundToDouble() ? '${value.toInt()}' : '$value';
  return unit == null || unit.isEmpty ? text : '$text $unit';
}

String _humanKey(String key) {
  final spaced = key.replaceAll('_', ' ').trim();
  return spaced.isEmpty ? key : spaced[0].toUpperCase() + spaced.substring(1);
}
