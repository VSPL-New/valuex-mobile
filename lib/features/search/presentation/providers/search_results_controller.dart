import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/search_repository.dart';
import '../../domain/search_criteria.dart';
import '../../domain/search_facet.dart';
import '../../domain/search_listing.dart';
import '../../domain/search_page.dart';
import '../../domain/transaction_intent.dart';

class SearchState {
  final SearchCriteria criteria;
  final List<SearchListing> items;

  /// Filters offered for the L3 category, from the first page of results.
  final List<SearchFacet> facets;
  final int totalItems;

  /// The first page is loading (also after a change or a refresh).
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasNext;
  final int nextPage;

  /// Why the first page could not be loaded; null when it did.
  final Object? error;
  final bool loadMoreFailed;

  /// The first page came back empty.
  final bool noResults;

  /// A Real Estate search waits for Buy, Rent or Lease.
  final bool needsIntent;

  const SearchState({
    this.criteria = const SearchCriteria(),
    this.items = const [],
    this.facets = const [],
    this.totalItems = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasNext = false,
    this.nextPage = 0,
    this.error,
    this.loadMoreFailed = false,
    this.noResults = false,
    this.needsIntent = false,
  });

  SearchState copyWith({
    SearchCriteria? criteria,
    List<SearchListing>? items,
    List<SearchFacet>? facets,
    int? totalItems,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasNext,
    int? nextPage,
    Object? error,
    bool clearError = false,
    bool? loadMoreFailed,
    bool? noResults,
    bool? needsIntent,
  }) {
    return SearchState(
      criteria: criteria ?? this.criteria,
      items: items ?? this.items,
      facets: facets ?? this.facets,
      totalItems: totalItems ?? this.totalItems,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasNext: hasNext ?? this.hasNext,
      nextPage: nextPage ?? this.nextPage,
      error: clearError ? null : (error ?? this.error),
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      noResults: noResults ?? this.noResults,
      needsIntent: needsIntent ?? this.needsIntent,
    );
  }
}

/// Runs the search for one screen: keeps the criteria and the pages, waits 400 ms after typing,
/// and ignores a response that belongs to an older request, so a slow answer for "lap" never
/// replaces the one for "laptop".
class SearchResultsController extends Notifier<SearchState> {
  static const Duration debounce = Duration(milliseconds: 400);

  final SearchCriteria initial;

  SearchResultsController(this.initial);

  Timer? _timer;
  int _request = 0;

  SearchRepository get _repository => ref.read(searchRepositoryProvider);

  @override
  SearchState build() {
    ref.onDispose(() => _timer?.cancel());
    final starts = !initial.isBlank && !initial.needsIntent;
    // Starts after the build, as a provider may not change its own state while it builds.
    if (starts) unawaited(Future<void>.microtask(load));
    return SearchState(
      criteria: initial,
      isLoading: starts,
      needsIntent: initial.needsIntent && !initial.isBlank,
    );
  }

  /// The text changed: searches after a short pause, or goes back to the start page when empty.
  void setQuery(String text) {
    final criteria = state.criteria.copyWith(query: text);
    state = state.copyWith(criteria: criteria);
    _timer?.cancel();
    _timer = Timer(debounce, load);
  }

  /// The user pressed search on the keyboard: no need to wait.
  Future<void> submit() => load();

  Future<void> applyCriteria(SearchCriteria criteria) {
    state = state.copyWith(criteria: criteria);
    return load();
  }

  Future<void> chooseIntent(TransactionIntent intent) =>
      applyCriteria(state.criteria.copyWith(intent: intent));

  Future<void> clearFilters() => applyCriteria(state.criteria.withoutFilters());

  Future<void> retry() => load();

  /// Pull to refresh: keeps what is shown until the new first page arrives.
  Future<void> refresh() => load(keepItems: true);

  /// Loads the first page of the current criteria.
  Future<void> load({bool keepItems = false}) async {
    _timer?.cancel();
    if (!ref.mounted) return;
    final request = ++_request;
    final criteria = state.criteria;

    if (criteria.isBlank) {
      state = SearchState(criteria: criteria);
      return;
    }
    if (criteria.needsIntent) {
      state = SearchState(criteria: criteria, needsIntent: true);
      return;
    }

    state = state.copyWith(
      items: keepItems ? null : const [],
      facets: keepItems ? null : const [],
      isLoading: true,
      isLoadingMore: false,
      loadMoreFailed: false,
      noResults: false,
      needsIntent: false,
      clearError: true,
    );
    try {
      final page = await _search(criteria, 0);
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(
        items: page.items,
        facets: page.facets,
        totalItems: page.totalItems,
        isLoading: false,
        hasNext: page.hasNext,
        nextPage: 1,
        noResults: page.items.isEmpty,
      );
    } on ApiError catch (error) {
      if (!ref.mounted || request != _request) return;
      if (error.code == 'ERROR_INTENT_REQUIRED') {
        // The app did not know the category was Real Estate; the server does.
        state = SearchState(
          criteria: criteria.copyWith(realEstate: true, intent: null),
          needsIntent: true,
        );
        return;
      }
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Adds the next page below the current ones; a failure keeps what is shown.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasNext) return;
    final request = _request;
    final criteria = state.criteria;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _search(criteria, state.nextPage);
      if (!ref.mounted || request != _request) return;
      final known = {for (final item in state.items) item.id};
      state = state.copyWith(
        items: [
          ...state.items,
          for (final item in page.items)
            if (!known.contains(item.id)) item,
        ],
        totalItems: page.totalItems,
        isLoadingMore: false,
        hasNext: page.hasNext,
        nextPage: state.nextPage + 1,
      );
    } on ApiError {
      if (ref.mounted && request == _request) {
        state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
      }
    }
  }

  Future<SearchPage> _search(SearchCriteria criteria, int page) {
    final place = ref.read(homeLocationControllerProvider).value;
    final near = place is LocationKnown ? place.location : null;
    return _repository.search(criteria, page: page, nearCity: near?.city, nearState: near?.state);
  }
}

final searchResultsControllerProvider = NotifierProvider.autoDispose
    .family<SearchResultsController, SearchState, SearchCriteria>(SearchResultsController.new);
