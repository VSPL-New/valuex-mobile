import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat.dart';
import 'chat_polling.dart';

/// The side of the conversations the list shows.
class ChatRoleFilter extends Notifier<ChatRole> {
  @override
  ChatRole build() => ChatRole.all;

  void select(ChatRole role) => state = role;
}

final chatRoleFilterProvider =
    NotifierProvider.autoDispose<ChatRoleFilter, ChatRole>(ChatRoleFilter.new);

/// The conversations loaded so far for the selected side.
class ChatListState {
  final List<ChatThread> threads;
  final int page;
  final bool hasNext;
  final bool loadingMore;

  const ChatListState({
    required this.threads,
    required this.page,
    required this.hasNext,
    this.loadingMore = false,
  });

  ChatListState copyWith({List<ChatThread>? threads, bool? loadingMore}) => ChatListState(
        threads: threads ?? this.threads,
        page: page,
        hasNext: hasNext,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

/// The Chats tab: conversations, newest activity first, refreshed while it is on screen.
class ChatListController extends AsyncNotifier<ChatListState> {
  @override
  Future<ChatListState> build() async {
    final role = ref.watch(chatRoleFilterProvider);
    final interval = ref.watch(chatPollIntervalProvider);
    if (interval != null) {
      final timer = Timer.periodic(interval, (_) => unawaited(_refreshQuietly(role)));
      ref.onDispose(timer.cancel);
    }
    final page = await ref.watch(chatRepositoryProvider).threads(role: role);
    return ChatListState(threads: page.items, page: page.page, hasNext: page.hasNext);
  }

  /// Reloads the first page for a pull to refresh; the error is left to the caller.
  Future<void> refresh() async {
    final role = ref.read(chatRoleFilterProvider);
    final page = await ref.read(chatRepositoryProvider).threads(role: role);
    if (!ref.mounted) return;
    state = AsyncData(ChatListState(threads: page.items, page: page.page, hasNext: page.hasNext));
  }

  /// Loads the next page. Returns false when it could not be loaded.
  Future<bool> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return true;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final role = ref.read(chatRoleFilterProvider);
      final next =
          await ref.read(chatRepositoryProvider).threads(role: role, page: current.page + 1);
      if (!ref.mounted) return true;
      final known = {for (final thread in current.threads) thread.threadId};
      state = AsyncData(ChatListState(
        threads: [
          ...current.threads,
          for (final thread in next.items)
            if (!known.contains(thread.threadId)) thread,
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

  /// A poll: the first page replaces what the phone has for those threads and the pages loaded
  /// further down stay. A failed poll changes nothing.
  Future<void> _refreshQuietly(ChatRole role) async {
    final current = state.value;
    if (current == null || current.loadingMore) return;
    try {
      final page = await ref.read(chatRepositoryProvider).threads(role: role);
      if (!ref.mounted) return;
      final fresh = {for (final thread in page.items) thread.threadId};
      state = AsyncData(ChatListState(
        threads: [
          ...page.items,
          for (final thread in current.threads)
            if (!fresh.contains(thread.threadId)) thread,
        ],
        page: current.page,
        hasNext: current.page == 0 ? page.hasNext : current.hasNext,
      ));
    } on Object {
      // The next poll tries again.
    }
  }
}

final chatListControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatListController, ChatListState>(
  ChatListController.new,
  retry: noAutoRetry,
);
