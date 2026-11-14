import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/saved_listings_repository.dart';
import '../../domain/saved_listing.dart';
import 'saved_hearts_controller.dart';

/// The Saved Items list so far: the pages loaded, newest saved first.
class SavedItemsState {
  final List<SavedListing> items;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final int? maxSaved;

  const SavedItemsState({
    required this.items,
    required this.page,
    required this.hasNext,
    this.loadingMore = false,
    this.maxSaved,
  });

  SavedItemsState copyWith({List<SavedListing>? items, bool? loadingMore}) => SavedItemsState(
        items: items ?? this.items,
        page: page,
        hasNext: hasNext,
        loadingMore: loadingMore ?? this.loadingMore,
        maxSaved: maxSaved,
      );
}

/// The Saved Items page (US-073): a paged list with remove. A removal shows at once and comes
/// back if the server refuses.
class SavedItemsController extends AsyncNotifier<SavedItemsState> {
  @override
  Future<SavedItemsState> build() async {
    final page = await ref.watch(savedListingsRepositoryProvider).list();
    return SavedItemsState(
      items: page.items,
      page: page.page,
      hasNext: page.hasNext,
      maxSaved: page.maxSaved,
    );
  }

  /// Appends the next page. Returns false when it could not be loaded.
  Future<bool> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return true;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref.read(savedListingsRepositoryProvider).list(page: current.page + 1);
      if (!ref.mounted) return true;
      final known = {for (final item in current.items) item.id};
      state = AsyncData(SavedItemsState(
        items: [
          ...current.items,
          for (final item in next.items)
            if (!known.contains(item.id)) item,
        ],
        page: next.page,
        hasNext: next.hasNext,
        maxSaved: next.maxSaved ?? current.maxSaved,
      ));
      return true;
    } on Object {
      if (ref.mounted) state = AsyncData(current.copyWith(loadingMore: false));
      return false;
    }
  }

  /// Takes the listing off the page and the hearts at once, then asks the server. Returns false,
  /// with the listing back where it was, when the server refuses.
  Future<bool> remove(String listingId) async {
    final current = state.value;
    if (current == null) return false;
    final index = current.items.indexWhere((item) => item.id == listingId);
    if (index < 0) return true;
    final removed = current.items[index];
    state = AsyncData(current.copyWith(items: [...current.items]..removeAt(index)));
    ref.read(savedHeartsProvider.notifier).markRemoved(listingId);
    try {
      await ref.read(savedListingsRepositoryProvider).remove(listingId);
      return true;
    } on Object {
      if (ref.mounted) _restore(removed, index);
      return false;
    }
  }

  void _restore(SavedListing item, int index) {
    final current = state.value;
    if (current == null || current.items.any((entry) => entry.id == item.id)) return;
    final at = index > current.items.length ? current.items.length : index;
    state = AsyncData(current.copyWith(items: [...current.items]..insert(at, item)));
  }
}

final savedItemsControllerProvider =
    AsyncNotifierProvider.autoDispose<SavedItemsController, SavedItemsState>(
  SavedItemsController.new,
  retry: noAutoRetry,
);
