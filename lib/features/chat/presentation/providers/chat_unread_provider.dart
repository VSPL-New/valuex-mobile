import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/chat_repository.dart';

/// The number of unread chat messages, read when a main screen opens; a failure counts as none so
/// the Chats tab never shows a dot it cannot back up.
final chatUnreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(chatRepositoryProvider).unreadCount(),
  retry: noAutoRetry,
);

/// Whether the dot on the Chats tab shows.
final chatsHasUnreadProvider = Provider.autoDispose<bool>(
  (ref) => (ref.watch(chatUnreadCountProvider).value ?? 0) > 0,
);
