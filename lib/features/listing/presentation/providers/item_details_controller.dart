import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/listing_repository.dart';
import '../../domain/category.dart';
import '../../domain/listing_details.dart';
import '../../domain/listing_schema.dart';

/// What the Item Details page is opened with: the draft, and what AI suggested if it did.
class ItemDetailsArgs {
  final String listingId;
  final AiSuggestion? suggestion;

  const ItemDetailsArgs({required this.listingId, this.suggestion});

  @override
  bool operator ==(Object other) =>
      other is ItemDetailsArgs &&
      other.listingId == listingId &&
      other.suggestion?.id == suggestion?.id;

  @override
  int get hashCode => Object.hash(listingId, suggestion?.id);
}

/// Where the form for the chosen category is: nothing chosen yet, loading, ready, or failed.
enum SchemaStatus { none, loading, ready, failed }

class ItemDetailsState {
  final ListingDetailsDraft draft;

  /// The chosen category with its path; null until one is chosen.
  final CategoryRef? category;
  final SchemaStatus schemaStatus;
  final ListingSchema? schema;
  final Object? schemaError;

  /// Common fields the seller has edited; hints are only shown for these.
  final Set<DetailsField> touched;

  /// Category-specific keys the seller has edited.
  final Set<String> touchedAttributes;
  final bool aiFilled;
  final bool isSaving;

  /// What AI suggested, as first shown; null when AI did not fill the page.
  final ListingDetailsDraft? suggested;

  const ItemDetailsState({
    this.draft = const ListingDetailsDraft(),
    this.category,
    this.schemaStatus = SchemaStatus.none,
    this.schema,
    this.schemaError,
    this.touched = const {},
    this.touchedAttributes = const {},
    this.aiFilled = false,
    this.isSaving = false,
    this.suggested,
  });

  bool get canContinue => schemaStatus == SchemaStatus.ready && draft.isValid(schema) && !isSaving;

  /// True while a field still holds exactly what AI suggested for it; editing it clears this.
  bool isAiGenerated(DetailsField field) {
    final ai = suggested;
    if (ai == null) return false;
    return switch (field) {
      DetailsField.title => ai.title.isNotEmpty && draft.title.trim() == ai.title.trim(),
      DetailsField.category => ai.categoryCode != null && draft.categoryCode == ai.categoryCode,
      DetailsField.condition => ai.condition != null && draft.condition == ai.condition,
      DetailsField.description =>
        ai.description.isNotEmpty && draft.description.trim() == ai.description.trim(),
      _ => false,
    };
  }

  /// Invalid common fields the seller has already worked on.
  List<DetailsField> get visibleHints => [
        for (final field in draft.invalidFields(schema))
          if (touched.contains(field)) field,
      ];

  /// Invalid category-specific keys the seller has already worked on.
  Set<String> get visibleAttributeHints =>
      draft.invalidAttributes(schema).toSet().intersection(touchedAttributes);

  ItemDetailsState copyWith({
    ListingDetailsDraft? draft,
    CategoryRef? category,
    SchemaStatus? schemaStatus,
    ListingSchema? schema,
    Object? schemaError,
    bool clearSchemaError = false,
    Set<DetailsField>? touched,
    Set<String>? touchedAttributes,
    bool? isSaving,
  }) {
    return ItemDetailsState(
      draft: draft ?? this.draft,
      category: category ?? this.category,
      schemaStatus: schemaStatus ?? this.schemaStatus,
      schema: schema ?? this.schema,
      schemaError: clearSchemaError ? null : (schemaError ?? this.schemaError),
      touched: touched ?? this.touched,
      touchedAttributes: touchedAttributes ?? this.touchedAttributes,
      aiFilled: aiFilled,
      isSaving: isSaving ?? this.isSaving,
      suggested: suggested,
    );
  }
}

/// US-114 and US-006: holds what the seller types, files the draft under a category, loads the
/// form that category asks for, saves it, and reports what the seller did with AI suggestions.
class ItemDetailsController extends Notifier<ItemDetailsState> {
  final ItemDetailsArgs args;

  ItemDetailsController(this.args);

  int _categoryRequest = 0;

  ListingRepository get _repository => ref.read(listingRepositoryProvider);

  @override
  ItemDetailsState build() {
    final suggestion = args.suggestion;
    final code = suggestion?.categoryCode;
    if (code != null) Future.microtask(() => selectCategory(code));
    return ItemDetailsState(
      draft: suggestion?.asDraft ?? const ListingDetailsDraft(),
      aiFilled: suggestion != null,
      suggested: suggestion?.asDraft,
    );
  }

  void setTitle(String value) => _edit(DetailsField.title, (d) => d.copyWith(title: value));

  void setCondition(ListingCondition condition) =>
      _edit(DetailsField.condition, (d) => d.copyWith(condition: condition));

  void setConditionNotes(String value) =>
      _edit(DetailsField.conditionNotes, (d) => d.copyWith(conditionNotes: value));

  void setDescription(String value) =>
      _edit(DetailsField.description, (d) => d.copyWith(description: value));

  void setPrice(String value) => _edit(DetailsField.price, (d) => d.copyWith(price: value));

  void setNegotiable(bool value) =>
      _edit(DetailsField.negotiable, (d) => d.copyWith(negotiable: value));

  void setQuantity(String value) =>
      _edit(DetailsField.quantity, (d) => d.copyWith(quantity: value));

  /// Sets, or with a blank value clears, one category-specific value.
  void setAttribute(String key, Object? value) {
    final attributes = {...state.draft.attributes};
    if (isBlankValue(value)) {
      attributes.remove(key);
    } else {
      attributes[key] = value;
    }
    state = state.copyWith(
      draft: state.draft.copyWith(attributes: attributes),
      touchedAttributes: {...state.touchedAttributes, key},
    );
  }

  /// Files the draft under the leaf [code] and loads its form. Values the new form does not ask
  /// are dropped, and fields that repeat the category name are filled in.
  Future<void> selectCategory(String code) async {
    final request = ++_categoryRequest;
    state = state.copyWith(
      draft: state.draft.copyWith(categoryCode: code),
      schemaStatus: SchemaStatus.loading,
      clearSchemaError: true,
      touched: {...state.touched, DetailsField.category},
    );
    try {
      await _repository.setCategory(args.listingId, code);
      final schema = await _repository.listingSchema(code);
      if (!ref.mounted || request != _categoryRequest) return;
      state = state.copyWith(
        draft: state.draft.copyWith(attributes: _fitToSchema(state.draft.attributes, schema)),
        category: schema.category,
        schema: schema,
        schemaStatus: SchemaStatus.ready,
      );
    } on ApiError catch (error) {
      if (!ref.mounted || request != _categoryRequest) return;
      state = state.copyWith(schemaStatus: SchemaStatus.failed, schemaError: error);
    }
  }

  /// Tries the current category again after a failure.
  Future<void> retryCategory() async {
    final code = state.draft.categoryCode;
    if (code != null) await selectCategory(code);
  }

  /// Saves the details; returns the error when the server refused them.
  Future<({bool saved, Object? error})> save() async {
    final schema = state.schema;
    if (schema == null || !state.canContinue) return (saved: false, error: null);
    state = state.copyWith(isSaving: true);
    final draft = state.draft;
    try {
      await _repository.saveDetails(args.listingId, draft, schema, city: _city());
      await _sendFeedback(draft);
      return (saved: true, error: null);
    } on ApiError catch (error) {
      return (saved: false, error: error);
    } finally {
      if (ref.mounted) state = state.copyWith(isSaving: false);
    }
  }

  Map<String, Object?> _fitToSchema(Map<String, Object?> current, ListingSchema schema) {
    final keys = schema.keys;
    final fitted = {
      for (final entry in current.entries)
        if (keys.contains(entry.key)) entry.key: entry.value,
    };
    for (final field in schema.fields) {
      final prefill = field.prefillOption;
      if (prefill != null && isBlankValue(fitted[field.key])) fitted[field.key] = prefill;
    }
    return fitted;
  }

  /// Only the city of the place chosen on Home is sent; never coordinates.
  String? _city() {
    final location = ref.read(homeLocationControllerProvider).value;
    return location is LocationKnown ? location.location.city : null;
  }

  Future<void> _sendFeedback(ListingDetailsDraft draft) async {
    final suggestion = args.suggestion;
    if (suggestion == null) return;
    final feedback = suggestionFeedback(suggestion, draft);
    if (feedback.isEmpty) return;
    try {
      await _repository.sendSuggestionFeedback(args.listingId, suggestion.id, feedback);
    } on ApiError {
      // Feedback is only for improving AI; it never blocks the seller.
    }
  }

  void _edit(DetailsField field, ListingDetailsDraft Function(ListingDetailsDraft) change) {
    state = state.copyWith(draft: change(state.draft), touched: {...state.touched, field});
  }
}

final itemDetailsControllerProvider = NotifierProvider.autoDispose
    .family<ItemDetailsController, ItemDetailsState, ItemDetailsArgs>(ItemDetailsController.new);
