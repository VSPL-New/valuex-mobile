import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/realtime/realtime_socket.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind('127.0.0.1', 0);
  });

  tearDown(() => server.close(force: true));

  Uri address(String query) => Uri.parse('ws://127.0.0.1:${server.port}/ws/v1$query');

  test('connects, sends and receives text, ignores binary frames and reports the close code',
      () async {
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((message) {
        if (message == 'close') {
          socket.close(4403, 'Account not active');
        } else {
          socket.add('echo:$message');
          socket.add(<int>[1, 2, 3]);
        }
      });
    });

    final socket = await connectWebSocket(address('?ticket=t'));
    final received = <String>[];
    final done = Completer<void>();
    socket.messages.listen(received.add, onDone: done.complete);

    socket.send('hi');
    while (received.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(received, ['echo:hi']);

    socket.send('close');
    await done.future.timeout(const Duration(seconds: 5));
    expect(socket.closeCode, 4403);
    await socket.close();
  });

  test('close ends the connection from the app side', () async {
    final serverSideClosed = Completer<int?>();
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {}, onDone: () => serverSideClosed.complete(socket.closeCode));
    });

    final socket = await connectWebSocket(address(''));
    await socket.close(1000, 'bye');

    expect(await serverSideClosed.future.timeout(const Duration(seconds: 5)), 1000);
  });

  test('a refused handshake throws', () async {
    server.listen((request) async {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
    });

    await expectLater(connectWebSocket(address('?ticket=bad')), throwsA(isA<Exception>()));
  });
}
