import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

/// The account's unread count for the Home bell and the Profile row. The Notifications page
/// keeps it in step with what the user reads, so no second request is needed on return.
class UnreadNotifications extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.watch(notificationsRepositoryProvider).unreadCount();

  void set(int count) => state = AsyncData(count < 0 ? 0 : count);
}

final unreadNotificationsProvider = AsyncNotifierProvider.autoDispose<UnreadNotifications, int>(
  UnreadNotifications.new,
  retry: noAutoRetry,
);

class NotificationsState {
  final List<AppNotification> items;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;
  final bool markingAll;

  const NotificationsState({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.markingAll = false,
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    bool? markingAll,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        markingAll: markingAll ?? this.markingAll,
      );
}

/// The Notifications page: the loaded pages, newest first, and the actions on them.
class NotificationsController extends AsyncNotifier<NotificationsState> {
  int _loadedPages = 1;

  NotificationsRepository get _repository => ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationsState> build() async {
    _loadedPages = 1;
    final first = await ref.watch(notificationsRepositoryProvider).page(0);
    _publishUnread(first.unread);
    return NotificationsState(items: first.items, hasMore: first.hasMore);
  }

  /// Fetches the next page when the user nears the end of the list.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final next = await _repository.page(_loadedPages);
      if (!ref.mounted) return;
      _loadedPages++;
      // Reads made while the page was loading are kept, so build on the latest state.
      final latest = state.value ?? current;
      final known = {for (final item in latest.items) item.id};
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...next.items.where((n) => !known.contains(n.id))],
          hasMore: next.hasMore,
          loadingMore: false,
          loadMoreFailed: false,
        ),
      );
      _publishUnread(next.unread);
    } on Object {
      if (!ref.mounted) return;
      state =
          AsyncData((state.value ?? current).copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  /// Marks one notification read at once and undoes it if the server refuses.
  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    final target = current.items.where((n) => n.id == id).firstOrNull;
    if (target == null || target.read) return;

    state = AsyncData(current.copyWith(items: _withRead(current.items, {id})));
    _adjustUnread(-1);
    try {
      await _repository.markRead(id);
    } on Object {
      if (!ref.mounted) return;
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(
          latest.copyWith(
            items: [
              for (final item in latest.items) item.id == id ? item.copyWith(read: false) : item,
            ],
          ),
        );
      }
      _adjustUnread(1);
    }
  }

  /// Throws when the server refuses, after putting the list back as it was.
  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.markingAll) return;
    final unreadIds = {
      for (final item in current.items)
        if (!item.read) item.id
    };
    final previousUnread = ref.read(unreadNotificationsProvider).value;

    state = AsyncData(
      current.copyWith(items: _withRead(current.items, unreadIds), markingAll: true),
    );
    ref.read(unreadNotificationsProvider.notifier).set(0);
    try {
      await _repository.markAllRead();
      if (!ref.mounted) return;
      state = AsyncData(state.value!.copyWith(markingAll: false));
    } on Object {
      if (ref.mounted) {
        final latest = state.value ?? current;
        state = AsyncData(
          latest.copyWith(
            items: [
              for (final item in latest.items)
                unreadIds.contains(item.id) ? item.copyWith(read: false) : item,
            ],
            markingAll: false,
          ),
        );
        if (previousUnread != null) {
          ref.read(unreadNotificationsProvider.notifier).set(previousUnread);
        }
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The error is shown by the page.
    }
  }

  static List<AppNotification> _withRead(List<AppNotification> items, Set<String> ids) => [
        for (final item in items) ids.contains(item.id) ? item.copyWith(read: true) : item,
      ];

  void _adjustUnread(int delta) {
    final count = ref.read(unreadNotificationsProvider).value;
    if (count != null) ref.read(unreadNotificationsProvider.notifier).set(count + delta);
  }

  /// Providers may not be changed while another one is still being built.
  void _publishUnread(int count) {
    scheduleMicrotask(() {
      if (ref.mounted) ref.read(unreadNotificationsProvider.notifier).set(count);
    });
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider.autoDispose<NotificationsController, NotificationsState>(
  NotificationsController.new,
  retry: noAutoRetry,
);
