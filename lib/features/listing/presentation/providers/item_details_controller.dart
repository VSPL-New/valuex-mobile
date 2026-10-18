import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/listing_repository.dart';
import '../../domain/listing_details.dart';

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

class ItemDetailsState {
  final ListingDetailsDraft draft;

  /// Fields the seller has edited; hints are only shown for these.
  final Set<DetailsField> touched;
  final bool aiFilled;
  final bool isSaving;

  /// What AI suggested, as first shown; null when AI did not fill the page.
  final ListingDetailsDraft? suggested;

  const ItemDetailsState({
    this.draft = const ListingDetailsDraft(),
    this.touched = const {},
    this.aiFilled = false,
    this.isSaving = false,
    this.suggested,
  });

  bool get canContinue => draft.isValid && !isSaving;

  /// True while a field still holds exactly what AI suggested for it; editing it clears this.
  bool isAiGenerated(DetailsField field) {
    final ai = suggested;
    if (ai == null) return false;
    return switch (field) {
      DetailsField.title => ai.title.isNotEmpty && draft.title.trim() == ai.title.trim(),
      DetailsField.category => ai.categorySlug != null && draft.categorySlug == ai.categorySlug,
      DetailsField.condition => ai.condition != null && draft.condition == ai.condition,
      DetailsField.description =>
        ai.description.isNotEmpty && draft.description.trim() == ai.description.trim(),
      DetailsField.price => false,
    };
  }

  /// Invalid fields the seller has already worked on.
  List<DetailsField> get visibleHints => [
        for (final field in draft.invalidFields)
          if (touched.contains(field)) field,
      ];

  ItemDetailsState copyWith({
    ListingDetailsDraft? draft,
    Set<DetailsField>? touched,
    bool? isSaving,
  }) {
    return ItemDetailsState(
      draft: draft ?? this.draft,
      touched: touched ?? this.touched,
      aiFilled: aiFilled,
      isSaving: isSaving ?? this.isSaving,
      suggested: suggested,
    );
  }
}

/// US-114: holds what the seller types, saves it to the draft and reports what the seller
/// did with AI suggestions when there were any.
class ItemDetailsController extends Notifier<ItemDetailsState> {
  final ItemDetailsArgs args;

  ItemDetailsController(this.args);

  ListingRepository get _repository => ref.read(listingRepositoryProvider);

  @override
  ItemDetailsState build() {
    final suggestion = args.suggestion;
    return ItemDetailsState(
      draft: suggestion?.asDraft ?? const ListingDetailsDraft(),
      aiFilled: suggestion != null,
      suggested: suggestion?.asDraft,
    );
  }

  void setTitle(String value) => _edit(DetailsField.title, (d) => d.copyWith(title: value));

  void setCategory(String slug) =>
      _edit(DetailsField.category, (d) => d.copyWith(categorySlug: slug));

  void setCondition(ListingCondition condition) =>
      _edit(DetailsField.condition, (d) => d.copyWith(condition: condition));

  void setDescription(String value) =>
      _edit(DetailsField.description, (d) => d.copyWith(description: value));

  void setPrice(String value) => _edit(DetailsField.price, (d) => d.copyWith(price: value));

  /// Saves the details; returns the error when the server refused them.
  Future<({bool saved, Object? error})> save() async {
    if (!state.canContinue) return (saved: false, error: null);
    state = state.copyWith(isSaving: true);
    final draft = state.draft;
    try {
      await _repository.saveDetails(args.listingId, draft, city: _city());
      await _sendFeedback(draft);
      return (saved: true, error: null);
    } on ApiError catch (error) {
      return (saved: false, error: error);
    } finally {
      if (ref.mounted) state = state.copyWith(isSaving: false);
    }
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
