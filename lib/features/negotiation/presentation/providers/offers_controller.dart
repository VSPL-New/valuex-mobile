import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/negotiation_repository.dart';
import '../../domain/offers.dart';
import 'negotiation_controller.dart';

/// The list shown on the Offers screen, kept when the person switches between Received and Sent.
class OffersFilterNotifier extends Notifier<OffersFilter> {
  @override
  OffersFilter build() => OffersFilter.pending;

  void select(OffersFilter filter) => state = filter;
}

final offersFilterProvider =
    NotifierProvider.autoDispose<OffersFilterNotifier, OffersFilter>(OffersFilterNotifier.new);

/// The offers loaded so far for one list.
class OffersListState {
  final List<OfferCard> items;
  final int page;
  final bool hasNext;
  final bool loadingMore;

  const OffersListState({
    required this.items,
    required this.page,
    required this.hasNext,
    this.loadingMore = false,
  });

  OffersListState copyWith({bool? loadingMore}) => OffersListState(
        items: items,
        page: page,
        hasNext: hasNext,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

/// One list of the Offers screen (US-076): received or sent, pending, accepted or closed. It is read
/// again when an event says a negotiation or a badge changed and after every reconnect (US-130), and
/// polled while the live connection is down. The server decides the order.
class OffersListController extends AsyncNotifier<OffersListState> {
  final OffersQuery query;
  Timer? _pollTimer;

  OffersListController(this.query);

  @override
  Future<OffersListState> build() async {
    ref.listen<Duration?>(
      negotiationPollIntervalProvider,
      (previous, next) => _pollEvery(next),
      fireImmediately: true,
    );
    ref.listen<int>(realtimeResyncProvider, (previous, next) => unawaited(_refreshQuietly()));
    final negotiationEvents = ref.watch(negotiationEventsProvider).listen(_onEvent);
    final badgeEvents = ref.watch(badgeEventsProvider).listen(_onEvent);
    ref.onDispose(() {
      negotiationEvents.cancel();
      badgeEvents.cancel();
      _pollTimer?.cancel();
    });
    return _first();
  }

  Future<OffersListState> _first() async {
    final page = await _load(0);
    return OffersListState(items: page.items, page: page.page, hasNext: page.hasNext);
  }

  Future<OffersPage> _load(int page) {
    final repository = ref.read(negotiationRepositoryProvider);
    final (side, filter) = query;
    return side == OffersSide.received
        ? repository.receivedOffers(filter, page: page)
        : repository.sentOffers(filter, page: page);
  }

  void _pollEvery(Duration? interval) {
    _pollTimer?.cancel();
    _pollTimer =
        interval == null ? null : Timer.periodic(interval, (_) => unawaited(_refreshQuietly()));
  }

  void _onEvent(RealtimeEvent event) {
    if (event.type == RealtimeTypes.negotiationUpdated ||
        event.type == RealtimeTypes.badgeUpdated) {
      unawaited(_refreshQuietly());
    }
  }

  /// Reloads the first page for a pull to refresh; the error is left to the caller.
  Future<void> refresh() async {
    final fresh = await _first();
    if (ref.mounted) state = AsyncData(fresh);
  }

  /// Loads the next page. Returns false when it could not be loaded.
  Future<bool> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return true;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _load(current.page + 1);
      if (!ref.mounted) return true;
      final known = {for (final card in current.items) card.negotiationId};
      state = AsyncData(OffersListState(
        items: [
          ...current.items,
          for (final card in next.items)
            if (!known.contains(card.negotiationId)) card,
        ],
        page: next.page,
        hasNext: next.hasNext,
      ));
      return true;
    } on Object {
      if (ref.mounted) state = AsyncData(current.copyWith(loadingMore: false));
      return false;
    }
  }

  /// A poll or an event: the first page is read again and the pages loaded further down are dropped,
  /// because the order may have changed. A failed read changes nothing.
  Future<void> _refreshQuietly() async {
    final current = state.value;
    if (current == null || current.loadingMore) return;
    try {
      final fresh = await _first();
      if (ref.mounted) state = AsyncData(fresh);
    } on Object {
      // The next event, poll or pull to refresh tries again.
    }
  }
}

final offersListControllerProvider =
    AsyncNotifierProvider.autoDispose.family<OffersListController, OffersListState, OffersQuery>(
  OffersListController.new,
  retry: noAutoRetry,
);

/// The counts of the seller's tabs. Read again on the same news as the lists.
class OffersSummaryController extends AsyncNotifier<OffersSummary> {
  @override
  Future<OffersSummary> build() async {
    ref.listen<int>(realtimeResyncProvider, (previous, next) => unawaited(_refreshQuietly()));
    final negotiationEvents = ref.watch(negotiationEventsProvider).listen((event) {
      if (event.type == RealtimeTypes.negotiationUpdated) unawaited(_refreshQuietly());
    });
    ref.onDispose(negotiationEvents.cancel);
    return ref.watch(negotiationRepositoryProvider).offersSummary();
  }

  Future<void> _refreshQuietly() async {
    if (state.value == null) return;
    try {
      final fresh = await ref.read(negotiationRepositoryProvider).offersSummary();
      if (ref.mounted) state = AsyncData(fresh);
    } on Object {
      // The next event or visit reads it again.
    }
  }
}

final offersSummaryProvider =
    AsyncNotifierProvider.autoDispose<OffersSummaryController, OffersSummary>(
  OffersSummaryController.new,
  retry: noAutoRetry,
);
