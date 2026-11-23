import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/calls/data/call_repository.dart';
import 'package:valuex_mobile/features/calls/domain/call.dart';

import '../../helpers/mocks.dart';
import 'call_fixtures.dart';

void main() {
  late MockApiClient client;
  late CallRepository repository;

  setUp(() {
    client = MockApiClient();
    repository = CallRepository(client);
  });

  T Function(Object?) parserOf<T>(Invocation invocation) =>
      invocation.namedArguments[#parse] as T Function(Object?);

  void stubPost(String path, Map<String, dynamic> json, {Object? data}) {
    when(() => client.post<CallSession>(
          path,
          data: data,
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<CallSession>(invocation)(json));
  }

  test('a voice call posts the listing to the voice route', () async {
    stubPost('/calls/voice', callJson(), data: {'listingId': 'l1'});

    final session = await repository.start('l1', type: CallType.voice);

    expect(session.callId, 'c1');
    expect(session.state, CallState.ringing);
  });

  test('a video call posts the listing to the video route', () async {
    stubPost('/calls/video', callJson(type: 'VIDEO'), data: {'listingId': 'l1'});

    final session = await repository.start('l1', type: CallType.video);

    expect(session.type, CallType.video);
  });

  test('reading a call asks for it by id', () async {
    when(() => client.get<CallSession>('/calls/c1', parse: any(named: 'parse'))).thenAnswer(
        (invocation) async => parserOf<CallSession>(invocation)(callJson(state: 'ACTIVE')));

    expect((await repository.get('c1')).state, CallState.active);
  });

  test('accept, decline, cancel, connected and end each post to their own route', () async {
    for (final action in ['accept', 'decline', 'cancel', 'connected', 'end']) {
      stubPost('/calls/c1/$action', callJson(state: 'ENDED', endReason: 'COMPLETED'));
    }

    expect((await repository.accept('c1')).state, CallState.ended);
    expect((await repository.decline('c1')).callId, 'c1');
    expect((await repository.cancel('c1')).callId, 'c1');
    expect((await repository.connected('c1')).callId, 'c1');
    expect((await repository.end('c1')).endReason, CallEndReason.completed);
    for (final action in ['accept', 'decline', 'cancel', 'connected', 'end']) {
      verify(() => client.post<CallSession>('/calls/c1/$action', parse: any(named: 'parse')))
          .called(1);
    }
  });

  test('join asks for the credentials of the call', () async {
    when(() => client.post<CallCredentials>('/calls/c1/join', parse: any(named: 'parse')))
        .thenAnswer(
      (invocation) async =>
          parserOf<CallCredentials>(invocation)(credentialsJson(media: 'VIDEO', withVideo: true)),
    );

    final credentials = await repository.join('c1');

    expect(credentials.media, CallType.video);
    expect(credentials.camera.maxFps, 24);
  });

  test('a heartbeat posts to the heartbeat route and expects nothing back', () async {
    when(() => client.post<void>('/calls/c1/heartbeat')).thenAnswer((_) async {});

    await repository.heartbeat('c1');

    verify(() => client.post<void>('/calls/c1/heartbeat')).called(1);
  });

  test('the history of a conversation reads its lines', () async {
    when(() => client.get<List<CallHistoryItem>>(
          '/calls',
          queryParameters: {'threadId': 't1', 'page': 0},
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<List<CallHistoryItem>>(invocation)({
          'items': [
            {'callId': 'c1', 'type': 'VOICE', 'direction': 'OUTGOING', 'outcome': 'COMPLETED'},
          ],
        }));

    final items = await repository.history('t1');

    expect(items.single.callId, 'c1');
    expect(items.single.outcome, 'COMPLETED');
  });
}
