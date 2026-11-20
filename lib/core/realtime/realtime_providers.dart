import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/account_active_provider.dart';
import '../../features/auth/presentation/providers/session_controller.dart';
import '../network/api_client.dart';
import 'realtime_client.dart';
import 'realtime_event.dart';
import 'realtime_socket.dart';
import 'realtime_ticket.dart';

final realtimeTicketRepositoryProvider = Provider<RealtimeTicketRepository>(
    (ref) => RealtimeTicketRepository(ref.watch(apiClientProvider)));

/// The one live connection of the signed-in session. Features do not use it directly: they read
/// [chatEventsProvider] and its siblings, [realtimeStatusProvider] and [realtimeResyncProvider].
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = WebSocketRealtimeClient(
    issueTicket: ref.watch(realtimeTicketRepositoryProvider).issue,
    openSocket: connectWebSocket,
    // The server closed the connection because the account is not active: read the account state
    // so the app shows its screen.
    onAccountInactive: () => ref.read(sessionControllerProvider.notifier).refreshStatus(),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// Where the connection stands. [RealtimeStatus.idle] until the connection controller starts.
class RealtimeStatusController extends Notifier<RealtimeStatus> {
  @override
  RealtimeStatus build() => RealtimeStatus.idle;

  void update(RealtimeStatus status) => state = status;
}

final realtimeStatusProvider =
    NotifierProvider<RealtimeStatusController, RealtimeStatus>(RealtimeStatusController.new);

/// Counts the moments a screen should re-read what it shows: after every (re)connect and when the
/// app returns to the foreground. A screen listens and calls its own REST re-read.
class RealtimeResyncController extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final realtimeResyncProvider =
    NotifierProvider<RealtimeResyncController, int>(RealtimeResyncController.new);

Provider<Stream<RealtimeEvent>> _eventsWithPrefix(List<String> prefixes) =>
    Provider<Stream<RealtimeEvent>>((ref) {
      final events = ref.watch(realtimeClientProvider).events;
      return events.where((event) => prefixes.any(event.type.startsWith));
    });

/// Events of conversations: `chat.*`.
final chatEventsProvider = _eventsWithPrefix(const ['chat.']);

/// Events of price negotiations and agreements (US-017 and later): `negotiation.*`, `agreement.*`.
final negotiationEventsProvider = _eventsWithPrefix(const ['negotiation.', 'agreement.']);

/// Badge counts changed (US-076): `badge.updated`.
final badgeEventsProvider = _eventsWithPrefix(const ['badge.']);

/// Events of calls (on hold): `call.*`.
final callEventsProvider = _eventsWithPrefix(const ['call.']);

/// Keeps the connection open while the account is active and the app is signed in, and mirrors its
/// status and resync moments into providers. Watched once, by the app.
final realtimeConnectionProvider = Provider<void>((ref) {
  final client = ref.watch(realtimeClientProvider);
  final subscriptions = [
    client.statuses.listen((status) => ref.read(realtimeStatusProvider.notifier).update(status)),
    client.resyncs.listen((_) => ref.read(realtimeResyncProvider.notifier).bump()),
  ];
  final observer = _ForegroundObserver(client);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  });

  final active = ref.watch(accountActiveProvider);
  if (active) {
    client.connect();
  } else {
    unawaited(client.disconnect());
  }
});

class _ForegroundObserver with WidgetsBindingObserver {
  final RealtimeClient _client;

  _ForegroundObserver(this._client);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _client.setForeground(state == AppLifecycleState.resumed);
  }
}
