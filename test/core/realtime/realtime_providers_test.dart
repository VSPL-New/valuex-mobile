import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_client.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/realtime/realtime_ticket.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_polling.dart';

import '../../helpers/mocks.dart';
import 'realtime_fakes.dart';

class _FakeSession extends SessionController {
  SessionState initial;
  int refreshes = 0;

  _FakeSession(this.initial);

  @override
  Future<SessionState> build() async => initial;

  void become(SessionState next) => state = AsyncData(next);

  @override
  Future<void> refreshStatus() async => refreshes++;
}

const _active = Authenticated(status: AccountStatus.active, aadhaarVerified: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRealtimeClient client;

  setUp(() => client = FakeRealtimeClient());

  ProviderContainer make({_FakeSession? session, List<Override> extra = const []}) {
    final container = ProviderContainer(overrides: [
      realtimeClientProvider.overrideWithValue(client),
      if (session != null) sessionControllerProvider.overrideWith(() => session),
      ...extra,
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('typed event providers', () {
    test('each one passes only the events of its own family', () async {
      final container = make();
      final chat = <String>[];
      final negotiation = <String>[];
      final calls = <String>[];
      container.read(chatEventsProvider).listen((e) => chat.add(e.type));
      container.read(negotiationEventsProvider).listen((e) => negotiation.add(e.type));
      container.read(callEventsProvider).listen((e) => calls.add(e.type));

      for (final type in [
        'chat.message.created',
        'chat.typing',
        'negotiation.updated',
        'agreement.updated',
        'call.incoming',
        'badge.updated',
      ]) {
        client.emit(type, {});
      }
      await Future<void>.delayed(Duration.zero);

      expect(chat, ['chat.message.created', 'chat.typing']);
      expect(negotiation, ['negotiation.updated', 'agreement.updated']);
      expect(calls, ['call.incoming']);
    });
  });

  group('the connection', () {
    test('opens while the account is active and closes when it stops being active or signs out',
        () async {
      final session = _FakeSession(_active);
      final container = make(session: session);
      container.listen(realtimeConnectionProvider, (_, __) {});
      await container.read(sessionControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(client.connects, 1);

      session.become(const Authenticated(status: AccountStatus.suspended, aadhaarVerified: true));
      await Future<void>.delayed(Duration.zero);
      expect(client.disconnects, 2);

      // Still not active: nothing changes for the client.
      session.become(const Unauthenticated());
      await Future<void>.delayed(Duration.zero);
      expect(client.disconnects, 2);

      session.become(_active);
      await Future<void>.delayed(Duration.zero);
      expect(client.connects, 2);
    });

    test('does not open before the session is known', () async {
      final container = make(session: _FakeSession(_active));

      container.listen(realtimeConnectionProvider, (_, __) {});

      expect(client.connects, 0);
      expect(client.disconnects, 1);
    });

    test('puts the status and the re-sync moments into providers', () async {
      final container = make(session: _FakeSession(_active));
      container.listen(realtimeConnectionProvider, (_, __) {});
      await container.read(sessionControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(realtimeStatusProvider), RealtimeStatus.idle);
      expect(container.read(realtimeResyncProvider), 0);

      client.setStatus(RealtimeStatus.connected);
      client.resync();
      client.resync();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(realtimeStatusProvider), RealtimeStatus.connected);
      expect(container.read(realtimeResyncProvider), 2);
    });

    test('tells the client when the app goes to the background and comes back', () async {
      final container = make(session: _FakeSession(_active));
      container.listen(realtimeConnectionProvider, (_, __) {});

      WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(client.foreground, isFalse);
      WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(client.foreground, isTrue);

      container.dispose();
      WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(client.foreground, isTrue);
    });
  });

  group('polling', () {
    test('every 15 seconds unless the live connection is open', () {
      final container = make();
      expect(container.read(chatPollIntervalProvider), const Duration(seconds: 15));

      for (final status in [
        RealtimeStatus.idle,
        RealtimeStatus.connecting,
        RealtimeStatus.reconnecting,
        RealtimeStatus.degraded,
        RealtimeStatus.stopped,
      ]) {
        container.read(realtimeStatusProvider.notifier).update(status);
        expect(container.read(chatPollIntervalProvider), const Duration(seconds: 15),
            reason: '$status');
      }

      container.read(realtimeStatusProvider.notifier).update(RealtimeStatus.connected);
      expect(container.read(chatPollIntervalProvider), isNull);
    });
  });

  group('the app client', () {
    test(
        'asks the server for a ticket, and reads the account state when the server says the account is not active',
        () async {
      final api = MockApiClient();
      when(() => api.post<RealtimeTicket>('/realtime/tickets', parse: any(named: 'parse')))
          .thenThrow(const ApiError(
              type: ApiErrorType.business, message: 'x', code: 'ERROR_ACCOUNT_NOT_ACTIVE'));
      final session = _FakeSession(_active);
      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(api),
        sessionControllerProvider.overrideWith(() => session),
      ]);
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.future);

      final realtime = container.read(realtimeClientProvider);
      expect(realtime, isA<WebSocketRealtimeClient>());
      realtime.connect();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(realtime.status, RealtimeStatus.stopped);
      expect(session.refreshes, 1);
    });

    test('the ticket call posts to the realtime endpoint and reads the answer', () async {
      final api = MockApiClient();
      when(() => api.post<RealtimeTicket>('/realtime/tickets', parse: any(named: 'parse')))
          .thenAnswer((invocation) async =>
              (invocation.namedArguments[#parse] as RealtimeTicket Function(Object?))({
                'ticket': 'abc',
                'expiresInSeconds': 30,
                'url': 'ws://h/ws/v1',
                'pingIntervalSeconds': 25,
              }));

      final ticket = await RealtimeTicketRepository(api).issue();

      expect(ticket.ticket, 'abc');
      expect(ticket.socketUri.toString(), 'ws://h/ws/v1?ticket=abc');
    });
  });
}
