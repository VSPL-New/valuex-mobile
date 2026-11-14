import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../data/listing_repository.dart';
import '../../domain/my_listings.dart';

class MyListingsState {
  final MyListingsFilter filter;
  final MyListingsSummary summary;
  final List<MyListingItem> items;

  /// The first page is loading (also after a filter change or a refresh).
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasNext;
  final int nextPage;

  /// Why the first page could not be loaded; null when it did.
  final Object? error;

  /// Listings the seller just deleted: hidden at once, and removed on the server when the undo
  /// window closes.
  final Set<String> pendingDeletes;

  const MyListingsState({
    this.filter = MyListingsFilter.all,
    this.summary = const MyListingsSummary(),
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasNext = false,
    this.nextPage = 0,
    this.error,
    this.pendingDeletes = const {},
  });

  List<MyListingItem> get visibleItems => [
        for (final item in items)
          if (!pendingDeletes.contains(item.id)) item,
      ];

  MyListingsState copyWith({
    MyListingsFilter? filter,
    MyListingsSummary? summary,
    List<MyListingItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasNext,
    int? nextPage,
    Object? error,
    bool clearError = false,
    Set<String>? pendingDeletes,
  }) {
    return MyListingsState(
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasNext: hasNext ?? this.hasNext,
      nextPage: nextPage ?? this.nextPage,
      error: clearError ? null : (error ?? this.error),
      pendingDeletes: pendingDeletes ?? this.pendingDeletes,
    );
  }
}

/// US-010 My Listings: loads the seller's listings a page at a time for the chosen filter, and
/// deletes a listing once its undo window has closed.
///
/// It is not auto-disposed: a delete started on this screen must still reach the server when the
/// seller leaves the screen before the undo window closes.
class MyListingsController extends Notifier<MyListingsState> {
  static const int pageSize = 20;

  int _request = 0;

  ListingRepository get _repository => ref.read(listingRepositoryProvider);

  @override
  MyListingsState build() => const MyListingsState();

  /// Loads the first page, for [filter] when given. Keeps what is shown while refreshing, so a
  /// pull to refresh does not blank the list.
  Future<void> load({MyListingsFilter? filter}) async {
    final request = ++_request;
    final chosen = filter ?? state.filter;
    final changed = chosen != state.filter;
    state = state.copyWith(
      filter: chosen,
      items: changed ? const [] : null,
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      final page = await _repository.myListings(filter: chosen, size: pageSize);
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(
        summary: page.summary,
        items: page.items,
        isLoading: false,
        hasNext: page.hasNext,
        nextPage: page.page + 1,
      );
    } on ApiError catch (error) {
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Adds the next page below the current ones; a failure keeps what is shown and the button.
  Future<ApiError?> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasNext) return null;
    final request = _request;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repository.myListings(
        filter: state.filter,
        page: state.nextPage,
        size: pageSize,
      );
      if (!ref.mounted || request != _request) return null;
      state = state.copyWith(
        summary: page.summary,
        items: [...state.items, ...page.items],
        isLoadingMore: false,
        hasNext: page.hasNext,
        nextPage: page.page + 1,
      );
      return null;
    } on ApiError catch (error) {
      if (ref.mounted && request == _request) state = state.copyWith(isLoadingMore: false);
      return error;
    }
  }

  /// Hides a listing while the seller can still undo the delete.
  void hide(String id) {
    state = state.copyWith(pendingDeletes: {...state.pendingDeletes, id});
  }

  /// The seller pressed Undo: the listing is back and nothing was sent to the server.
  void restore(String id) {
    state = state.copyWith(pendingDeletes: {...state.pendingDeletes}..remove(id));
  }

  /// The undo window closed: deletes the listing on the server. On failure the listing comes back
  /// and the error is returned.
  Future<ApiError?> commitDelete(String id) async {
    final deleted = state.items.where((item) => item.id == id).firstOrNull;
    try {
      await _repository.deleteListing(id);
    } on ApiError catch (error) {
      if (ref.mounted) restore(id);
      return error;
    }
    if (!ref.mounted) return null;
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id != id) item,
      ],
      pendingDeletes: {...state.pendingDeletes}..remove(id),
      summary: _without(deleted),
    );
    return null;
  }

  /// Marks a property Sold, Rented or Leased, then reloads the page so the card, its status and the
  /// counts show what the server now says. Returns the error when the server refused.
  Future<ApiError?> close(String id, ClosedOutcome outcome) async {
    try {
      await _repository.closeListing(id, outcome);
    } on ApiError catch (error) {
      return error;
    }
    if (ref.mounted) await load();
    return null;
  }

  /// The counts after a listing is gone: every listing counts toward the total, only a published
  /// one toward Active.
  MyListingsSummary _without(MyListingItem? deleted) {
    final summary = state.summary;
    if (deleted == null) return summary;
    return MyListingsSummary(
      total: summary.total > 0 ? summary.total - 1 : 0,
      active:
          deleted.status == 'PUBLISHED' && summary.active > 0 ? summary.active - 1 : summary.active,
      sold: summary.sold,
      totalViews: summary.totalViews,
    );
  }
}

final myListingsControllerProvider =
    NotifierProvider<MyListingsController, MyListingsState>(MyListingsController.new);
