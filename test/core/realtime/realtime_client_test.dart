import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_client.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_socket.dart';
import 'package:valuex_mobile/core/realtime/realtime_ticket.dart';

import 'realtime_fakes.dart';

/// A random source that always answers the middle, so the retry delay is exactly the base delay.
class _Middle implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.5;

  @override
  int nextInt(int max) => 0;
}

class _BrokenSocket extends FakeSocket {
  @override
  void send(String text) => throw StateError('closed');
}

class _Rig {
  final List<FakeSocket> sockets = [];
  final List<Uri> uris = [];
  final List<RealtimeStatus> statuses = [];
  final List<RealtimeEvent> events = [];
  int tickets = 0;
  int resyncs = 0;
  int inactive = 0;

  /// Failures the next opens raise, consumed one by one; an empty list opens a socket.
  final List<Object> openFailures = [];
  Object? ticketFailure;
  late final WebSocketRealtimeClient client;

  _Rig() {
    client = WebSocketRealtimeClient(
      issueTicket: () async {
        tickets++;
        final failure = ticketFailure;
        if (failure != null) throw failure;
        return const RealtimeTicket(
          ticket: 't-1',
          expiresInSeconds: 30,
          url: 'ws://host/ws/v1',
          pingIntervalSeconds: 25,
        );
      },
      openSocket: (uri) async {
        uris.add(uri);
        if (openFailures.isNotEmpty) throw openFailures.removeAt(0);
        final socket = FakeSocket();
        sockets.add(socket);
        return socket;
      },
      onAccountInactive: () async => inactive++,
      random: _Middle(),
    );
    client.statuses.listen(statuses.add);
    client.events.listen(events.add);
    client.resyncs.listen((_) => resyncs++);
  }

  FakeSocket get socket => sockets.last;
}

ApiError _error(String? code, {ApiErrorType type = ApiErrorType.business}) =>
    ApiError(type: type, message: 'x', code: code);

void _run(void Function(FakeAsync async, _Rig rig) body) =>
    fakeAsync((async) => body(async, _Rig()));

void main() {
  group('connecting', () {
    test('asks for a ticket, opens the socket with it, says it is in the foreground and re-syncs',
        () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();

        expect(rig.client.status, RealtimeStatus.connected);
        expect(rig.statuses, [RealtimeStatus.connecting, RealtimeStatus.connected]);
        expect(rig.uris.single.toString(), 'ws://host/ws/v1?ticket=t-1');
        expect(rig.socket.sentFrames, [
          {
            'type': 'app.state',
            'data': {'foreground': true},
          }
        ]);
        expect(rig.resyncs, 1);
      });
    });

    test('is idempotent while connected', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();
        rig.client.connect();
        async.flushMicrotasks();

        expect(rig.tickets, 1);
        expect(rig.sockets, hasLength(1));
      });
    });

    test('pings at the interval the server gave', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 24));
        expect(rig.socket.sentFrames.where((f) => f['type'] == 'ping'), isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(rig.socket.sentFrames.where((f) => f['type'] == 'ping'), hasLength(1));
        async.elapse(const Duration(seconds: 25));
        expect(rig.socket.sentFrames.where((f) => f['type'] == 'ping'), hasLength(2));
      });
    });

    test('a connect that is overtaken by a disconnect closes the late socket', () {
      fakeAsync((async) {
        final opening = Completer<RealtimeSocket>();
        final late = FakeSocket();
        final client = WebSocketRealtimeClient(
          issueTicket: () async => const RealtimeTicket(
              ticket: 't', expiresInSeconds: 30, url: 'ws://h/ws/v1', pingIntervalSeconds: 25),
          openSocket: (uri) => opening.future,
          random: _Middle(),
        );
        client.connect();
        async.flushMicrotasks();
        unawaited(client.disconnect());
        async.flushMicrotasks();
        opening.complete(late);
        async.flushMicrotasks();

        expect(late.closed, isTrue);
        expect(client.status, RealtimeStatus.idle);
      });
    });
  });

  group('events', () {
    test('delivers each event once and drops pongs and frames that are not events', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();

        rig.socket.push({
          'type': 'chat.read',
          'id': 'e1',
          'data': {'upToSeq': 3}
        });
        rig.socket.push({
          'type': 'chat.read',
          'id': 'e1',
          'data': {'upToSeq': 3}
        });
        rig.socket.push({'type': 'pong', 'id': 'p1'});
        rig.socket.pushRaw('not json');
        rig.socket.push({'type': 'chat.read'});
        rig.socket.push({
          'type': 'chat.typing',
          'id': 'e2',
          'data': {'typing': true}
        });
        async.flushMicrotasks();

        expect(rig.events.map((e) => e.id), ['e1', 'e2']);
        expect(rig.events.first.data['upToSeq'], 3);
      });
    });
  });

  group('losing the connection', () {
    test('retries after 1, 2 and 4 seconds, then connects', () {
      _run((async, rig) {
        rig.openFailures.addAll([StateError('a'), StateError('b'), StateError('c')]);
        rig.client.connect();
        async.flushMicrotasks();
        expect(rig.uris, hasLength(1));
        expect(rig.client.status, RealtimeStatus.reconnecting);

        async.elapse(const Duration(milliseconds: 999));
        expect(rig.uris, hasLength(1));
        async.elapse(const Duration(milliseconds: 1));
        expect(rig.uris, hasLength(2));
        async.elapse(const Duration(seconds: 2));
        expect(rig.uris, hasLength(3));
        async.elapse(const Duration(seconds: 4));
        expect(rig.uris, hasLength(4));
        expect(rig.client.status, RealtimeStatus.connected);
      });
    });

    test('never waits longer than 30 seconds between tries', () {
      _run((async, rig) {
        rig.openFailures.addAll(List.generate(9, (i) => StateError('$i')));
        rig.client.connect();
        async.flushMicrotasks();
        for (final seconds in [1, 2, 4, 8, 16, 30, 30]) {
          final before = rig.uris.length;
          async.elapse(Duration(seconds: seconds) - const Duration(milliseconds: 1));
          expect(rig.uris, hasLength(before));
          async.elapse(const Duration(milliseconds: 1));
          expect(rig.uris, hasLength(before + 1));
        }
      });
    });

    test('starts the backoff over after a minute of a stable connection', () {
      _run((async, rig) {
        rig.openFailures.addAll([StateError('a'), StateError('b')]);
        rig.client.connect();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(rig.client.status, RealtimeStatus.connected);

        async.elapse(const Duration(seconds: 61));
        rig.socket.serverClose(1006);
        async.flushMicrotasks();
        final before = rig.uris.length;
        async.elapse(const Duration(seconds: 1));

        expect(rig.uris, hasLength(before + 1));
      });
    });

    test('keeps the backoff going when the connection did not last a minute', () {
      _run((async, rig) {
        rig.openFailures.addAll([StateError('a'), StateError('b')]);
        rig.client.connect();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        async.elapse(const Duration(seconds: 5));
        rig.socket.serverClose(null);
        async.flushMicrotasks();
        final before = rig.uris.length;

        async.elapse(const Duration(seconds: 3));
        expect(rig.uris, hasLength(before));
        async.elapse(const Duration(seconds: 1));
        expect(rig.uris, hasLength(before + 1));
      });
    });

    test('reconnects after a broken connection and re-syncs', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();
        rig.socket.fail();
        async.flushMicrotasks();
        expect(rig.client.status, RealtimeStatus.reconnecting);

        async.elapse(const Duration(seconds: 1));

        expect(rig.client.status, RealtimeStatus.connected);
        expect(rig.sockets, hasLength(2));
        expect(rig.resyncs, 2);
      });
    });

    test('goes to degraded after a minute without a connection and recovers when it opens', () {
      _run((async, rig) {
        rig.openFailures.addAll(List.generate(20, (i) => StateError('$i')));
        rig.client.connect();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 59));
        expect(rig.client.status, RealtimeStatus.reconnecting);
        async.elapse(const Duration(seconds: 1));
        expect(rig.client.status, RealtimeStatus.degraded);

        rig.openFailures.clear();
        async.elapse(const Duration(seconds: 30));
        expect(rig.client.status, RealtimeStatus.connected);
      });
    });
  });

  group('close codes', () {
    void connected(FakeAsync async, _Rig rig) {
      rig.client.connect();
      async.flushMicrotasks();
    }

    test('4401 gets a new ticket at once', () {
      _run((async, rig) {
        connected(async, rig);
        rig.socket.serverClose(4401);
        async.flushMicrotasks();

        expect(rig.tickets, 2);
        expect(rig.client.status, RealtimeStatus.connected);
      });
    });

    test('4403 stops for good, tells the app, and a return to the foreground does not reconnect',
        () {
      _run((async, rig) {
        connected(async, rig);
        rig.socket.serverClose(4403);
        async.flushMicrotasks();

        expect(rig.client.status, RealtimeStatus.stopped);
        expect(rig.inactive, 1);
        async.elapse(const Duration(minutes: 5));
        rig.client.setForeground(true);
        async.flushMicrotasks();
        expect(rig.tickets, 1);

        rig.client.connect();
        async.flushMicrotasks();
        expect(rig.client.status, RealtimeStatus.connected);
      });
    });

    test('4409 waits for the user: no retry, then a return to the foreground connects', () {
      _run((async, rig) {
        connected(async, rig);
        rig.socket.serverClose(4409);
        async.flushMicrotasks();

        expect(rig.client.status, RealtimeStatus.stopped);
        async.elapse(const Duration(minutes: 5));
        expect(rig.tickets, 1);
        expect(rig.inactive, 0);

        rig.client.setForeground(true);
        async.flushMicrotasks();
        expect(rig.client.status, RealtimeStatus.connected);
      });
    });

    test('4429 backs off 30 seconds', () {
      _run((async, rig) {
        connected(async, rig);
        rig.socket.serverClose(4429);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 29));
        expect(rig.tickets, 1);
        async.elapse(const Duration(seconds: 1));
        expect(rig.tickets, 2);
      });
    });

    for (final code in [1001, 4408, 4413]) {
      test('$code reconnects with the usual backoff', () {
        _run((async, rig) {
          connected(async, rig);
          rig.socket.serverClose(code);
          async.flushMicrotasks();
          expect(rig.client.status, RealtimeStatus.reconnecting);

          async.elapse(const Duration(seconds: 1));

          expect(rig.client.status, RealtimeStatus.connected);
        });
      });
    }
  });

  group('the ticket call failing', () {
    test('realtime switched off on the server: degraded, and it keeps trying', () {
      _run((async, rig) {
        rig.ticketFailure = _error('ERROR_REALTIME_UNAVAILABLE');
        rig.client.connect();
        async.flushMicrotasks();

        expect(rig.client.status, RealtimeStatus.degraded);
        async.elapse(const Duration(seconds: 1));
        expect(rig.tickets, 2);
        expect(rig.client.status, RealtimeStatus.degraded);

        rig.ticketFailure = null;
        async.elapse(const Duration(seconds: 2));
        expect(rig.client.status, RealtimeStatus.connected);
      });
    });

    test('an account that is not active: stopped, the app is told, no retry', () {
      _run((async, rig) {
        rig.ticketFailure = _error('ERROR_ACCOUNT_NOT_ACTIVE');
        rig.client.connect();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 2));

        expect(rig.client.status, RealtimeStatus.stopped);
        expect(rig.inactive, 1);
        expect(rig.tickets, 1);
      });
    });

    test('an ended session goes idle and does not retry', () {
      _run((async, rig) {
        rig.ticketFailure = _error(null, type: ApiErrorType.sessionExpired);
        rig.client.connect();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 2));

        expect(rig.client.status, RealtimeStatus.idle);
        expect(rig.tickets, 1);
      });
    });

    test('a network failure is retried with backoff', () {
      _run((async, rig) {
        rig.ticketFailure = _error(null, type: ApiErrorType.network);
        rig.client.connect();
        async.flushMicrotasks();
        expect(rig.client.status, RealtimeStatus.reconnecting);

        async.elapse(const Duration(seconds: 1));
        expect(rig.tickets, 2);
        rig.ticketFailure = StateError('boom');
        async.elapse(const Duration(seconds: 2));
        expect(rig.tickets, 3);
      });
    });

    test('a failing account callback does not break the client', () {
      fakeAsync((async) {
        final client = WebSocketRealtimeClient(
          issueTicket: () async => throw _error('ERROR_ACCOUNT_NOT_ACTIVE'),
          openSocket: (uri) async => FakeSocket(),
          onAccountInactive: () async => throw StateError('offline'),
          random: _Middle(),
        );
        client.connect();
        async.flushMicrotasks();

        expect(client.status, RealtimeStatus.stopped);
      });
    });
  });

  group('foreground and background', () {
    test('goes to the background: says so, and closes the socket after 30 seconds', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();

        rig.client.setForeground(false);
        expect(rig.socket.sentFrames.last, {
          'type': 'app.state',
          'data': {'foreground': false},
        });
        async.elapse(const Duration(seconds: 29));
        expect(rig.client.status, RealtimeStatus.connected);
        async.elapse(const Duration(seconds: 1));

        expect(rig.client.status, RealtimeStatus.idle);
        expect(rig.socket.closed, isTrue);
        async.elapse(const Duration(minutes: 2));
        expect(rig.tickets, 1);
      });
    });

    test('a quick return keeps the connection, says so and re-syncs', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();
        rig.client.setForeground(false);
        async.elapse(const Duration(seconds: 10));

        rig.client.setForeground(true);
        async.elapse(const Duration(minutes: 1));

        expect(rig.client.status, RealtimeStatus.connected);
        expect(rig.socket.sentFrames.where((f) => f['type'] == 'app.state').last['data'],
            {'foreground': true});
        expect(rig.resyncs, 2);
      });
    });

    test('a return after the socket was closed connects again and re-syncs', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();
        rig.client.setForeground(false);
        async.elapse(const Duration(seconds: 31));

        rig.client.setForeground(true);
        async.flushMicrotasks();

        expect(rig.client.status, RealtimeStatus.connected);
        expect(rig.sockets, hasLength(2));
        expect(rig.resyncs, 2);
      });
    });

    test('a return while the client was never asked to connect does nothing', () {
      _run((async, rig) {
        rig.client.setForeground(true);
        async.flushMicrotasks();

        expect(rig.tickets, 0);
      });
    });
  });

  group('disconnect and send', () {
    test('disconnect closes the socket, stays idle and can connect again', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();

        unawaited(rig.client.disconnect());
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 2));

        expect(rig.client.status, RealtimeStatus.idle);
        expect(rig.socket.closed, isTrue);
        expect(rig.tickets, 1);

        rig.client.connect();
        async.flushMicrotasks();
        expect(rig.client.status, RealtimeStatus.connected);
      });
    });

    test('sends a frame only while connected', () {
      _run((async, rig) {
        expect(rig.client.send('chat.read', {'upToSeq': 1}), isFalse);

        rig.client.connect();
        async.flushMicrotasks();

        expect(rig.client.send('chat.read', {'upToSeq': 1}), isTrue);
        expect(rig.client.send('ping'), isTrue);
        expect(rig.socket.sentFrames.sublist(1), [
          {
            'type': 'chat.read',
            'data': {'upToSeq': 1},
          },
          {'type': 'ping'},
        ]);
      });
    });

    test('a socket that fails to send makes send answer false', () {
      fakeAsync((async) {
        final client = WebSocketRealtimeClient(
          issueTicket: () async => const RealtimeTicket(
              ticket: 't', expiresInSeconds: 30, url: 'ws://h/ws/v1', pingIntervalSeconds: 25),
          openSocket: (uri) async => _BrokenSocket(),
          random: _Middle(),
        );
        client.connect();
        async.flushMicrotasks();

        expect(client.status, RealtimeStatus.connected);
        expect(client.send('ping'), isFalse);
      });
    });

    test('dispose stops everything and later calls do nothing', () {
      _run((async, rig) {
        rig.client.connect();
        async.flushMicrotasks();

        rig.client.dispose();
        async.flushMicrotasks();
        rig.client.dispose();
        rig.client.connect();
        rig.client.setForeground(true);
        async.flushMicrotasks();

        expect(rig.socket.closed, isTrue);
        expect(rig.tickets, 1);
      });
    });
  });

  group('the socket factory', () {
    test('uses web_socket_channel for the app', () {
      expect(connectWebSocket, isA<RealtimeSocketFactory>());
    });
  });
}
