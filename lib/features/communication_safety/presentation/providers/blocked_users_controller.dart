import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/communication_safety_repository.dart';
import '../../domain/communication_safety.dart';

/// The blocked users so far: the pages loaded, newest block first.
class BlockedUsersState {
  final List<BlockedUser> items;
  final int page;
  final bool hasNext;
  final bool loadingMore;

  const BlockedUsersState({
    required this.items,
    required this.page,
    required this.hasNext,
    this.loadingMore = false,
  });

  BlockedUsersState copyWith({List<BlockedUser>? items, bool? loadingMore}) => BlockedUsersState(
        items: items ?? this.items,
        page: page,
        hasNext: hasNext,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

/// The Blocked users page (US-132): a paged list with unblock. An unblock shows at once and comes
/// back if the server refuses.
class BlockedUsersController extends AsyncNotifier<BlockedUsersState> {
  @override
  Future<BlockedUsersState> build() async {
    final page = await ref.watch(communicationSafetyRepositoryProvider).listBlocked();
    return BlockedUsersState(items: page.items, page: page.page, hasNext: page.hasNext);
  }

  /// Appends the next page. Returns false when it could not be loaded.
  Future<bool> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return true;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next =
          await ref.read(communicationSafetyRepositoryProvider).listBlocked(page: current.page + 1);
      if (!ref.mounted) return true;
      final known = {for (final item in current.items) item.userId};
      state = AsyncData(BlockedUsersState(
        items: [
          ...current.items,
          for (final item in next.items)
            if (!known.contains(item.userId)) item,
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

  /// Takes the user off the page at once, then asks the server. Returns false, with the user back
  /// where they were, when the server refuses.
  Future<bool> unblock(String userId) async {
    final current = state.value;
    if (current == null) return false;
    final index = current.items.indexWhere((item) => item.userId == userId);
    if (index < 0) return true;
    final removed = current.items[index];
    state = AsyncData(current.copyWith(items: [...current.items]..removeAt(index)));
    try {
      await ref.read(communicationSafetyRepositoryProvider).unblock(userId);
      return true;
    } on Object {
      if (ref.mounted) _restore(removed, index);
      return false;
    }
  }

  void _restore(BlockedUser user, int index) {
    final current = state.value;
    if (current == null || current.items.any((entry) => entry.userId == user.userId)) return;
    final at = index > current.items.length ? current.items.length : index;
    state = AsyncData(current.copyWith(items: [...current.items]..insert(at, user)));
  }
}

final blockedUsersControllerProvider =
    AsyncNotifierProvider.autoDispose<BlockedUsersController, BlockedUsersState>(
  BlockedUsersController.new,
  retry: noAutoRetry,
);
