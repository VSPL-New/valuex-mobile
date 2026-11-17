import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/chat_repository.dart';

/// The number of unread chat messages, read when a main screen opens and again when an event says
/// it changed (a message, a read receipt, a closed thread) or the live connection came back, so the
/// dot on the Chats tab is live without polling (US-130). A failure counts as none so the tab never
/// shows a dot it cannot back up.
final chatUnreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) {
    const changes = {
      RealtimeTypes.chatMessageCreated,
      RealtimeTypes.chatRead,
      RealtimeTypes.chatThreadUpdated,
    };
    Timer? debounce;
    void refreshSoon() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 300), ref.invalidateSelf);
    }

    final events = ref.watch(chatEventsProvider).listen((event) {
      if (changes.contains(event.type)) refreshSoon();
    });
    ref.listen<int>(realtimeResyncProvider, (previous, next) => refreshSoon());
    ref.onDispose(() {
      events.cancel();
      debounce?.cancel();
    });
    return ref.watch(chatRepositoryProvider).unreadCount();
  },
  retry: noAutoRetry,
);

/// Whether the dot on the Chats tab shows.
final chatsHasUnreadProvider = Provider.autoDispose<bool>(
  (ref) => (ref.watch(chatUnreadCountProvider).value ?? 0) > 0,
);
