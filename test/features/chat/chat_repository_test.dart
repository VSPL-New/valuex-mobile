import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/chat/data/chat_repository.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';

import '../../helpers/mocks.dart';
import 'chat_fixtures.dart';

class _MockListingRepository extends Mock implements ListingRepository {}

void main() {
  late MockApiClient client;
  late _MockListingRepository uploads;
  late ChatRepository repository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    client = MockApiClient();
    uploads = _MockListingRepository();
    repository = ChatRepository(client, uploads);
  });

  T Function(Object?) parserOf<T>(Invocation invocation) =>
      invocation.namedArguments[#parse] as T Function(Object?);

  test('open posts the listing and tells a new thread (201) from an existing one (200)', () async {
    for (final (status, created) in [(201, true), (200, false)]) {
      when(() => client.postWithStatus<ChatThread>(
                '/chats',
                data: {'listingId': 'l1'},
                parse: any(named: 'parse'),
              ))
          .thenAnswer(
              (invocation) async => (parserOf<ChatThread>(invocation)(threadJson()), status));

      final opened = await repository.open('l1');

      expect(opened.created, created);
      expect(opened.thread.threadId, 't1');
    }
  });

  test('threads ask for the side, the page and the fixed size', () async {
    when(() => client.get<ChatThreadPage>(
          '/chats',
          queryParameters: {'role': 'SELLING', 'page': 2, 'size': ChatRepository.threadPageSize},
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<ChatThreadPage>(invocation)({
          'items': [threadJson(role: 'SELLER')],
          'page': 2,
          'hasNext': false,
        }));

    final result = await repository.threads(role: ChatRole.selling, page: 2);

    expect(result.items.single.isBuyer, isFalse);
    expect(result.page, 2);
  });

  test('thread reads one conversation by id', () async {
    when(() => client.get<ChatThread>('/chats/t1', parse: any(named: 'parse')))
        .thenAnswer((invocation) async => parserOf<ChatThread>(invocation)(threadJson(lastSeq: 4)));

    expect((await repository.thread('t1')).lastSeq, 4);
  });

  test('messages pass only the cursors that are given', () async {
    when(() => client.get<ChatMessagePage>(
          '/chats/t1/messages',
          queryParameters: {'afterSeq': 7, 'limit': ChatRepository.messagePageSize},
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<ChatMessagePage>(invocation)({
          'messages': [messageJson(seq: 8)],
          'hasMore': false
        }));
    when(() => client.get<ChatMessagePage>(
              '/chats/t1/messages',
              queryParameters: {'beforeSeq': 5, 'limit': ChatRepository.messagePageSize},
              parse: any(named: 'parse'),
            ))
        .thenAnswer((invocation) async => parserOf<ChatMessagePage>(invocation)({'messages': []}));

    expect((await repository.messages('t1', afterSeq: 7)).messages.single.seq, 8);
    expect((await repository.messages('t1', beforeSeq: 5)).messages, isEmpty);
  });

  test('sendText sends the client id and leaves the agreement out unless it was given', () async {
    when(() => client.post<ChatMessage>(
              '/chats/t1/messages',
              data: any(named: 'data'),
              parse: any(named: 'parse'),
            ))
        .thenAnswer((invocation) async =>
            parserOf<ChatMessage>(invocation)(messageJson(seq: 5, fromMe: true)));

    await repository.sendText('t1', clientMessageId: 'c1', body: 'Hello');
    await repository.sendText('t1', clientMessageId: 'c1', body: 'Hello', agreed: true);

    final sent = verify(() => client.post<ChatMessage>(
          '/chats/t1/messages',
          data: captureAny(named: 'data'),
          parse: any(named: 'parse'),
        )).captured;
    expect(sent[0], {'clientMessageId': 'c1', 'type': 'TEXT', 'body': 'Hello'});
    expect(sent[1], {
      'clientMessageId': 'c1',
      'type': 'TEXT',
      'body': 'Hello',
      'policyAgreement': {'accepted': true, 'version': policyAgreementVersion},
    });
  });

  test('sendImage sends the media id', () async {
    when(() => client.post<ChatMessage>(
              '/chats/t1/messages',
              data: {'clientMessageId': 'c2', 'type': 'IMAGE', 'mediaId': 'media-1'},
              parse: any(named: 'parse'),
            ))
        .thenAnswer((invocation) async =>
            parserOf<ChatMessage>(invocation)(messageJson(seq: 6, fromMe: true, type: 'IMAGE')));

    final stored = await repository.sendImage('t1', clientMessageId: 'c2', mediaId: 'media-1');

    expect(stored.type, ChatMessageType.image);
  });

  test('uploadImage asks for a chat picture upload, sends the bytes and completes it', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    when(() => client.post<UploadTicket>(
              '/media/uploads',
              data: any(named: 'data'),
              parse: any(named: 'parse'),
            ))
        .thenAnswer((invocation) async => parserOf<UploadTicket>(invocation)(
            {'mediaId': 'media-1', 'uploadUrl': 'https://storage/put'}));
    when(() => uploads.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
    when(() => uploads.completeUpload(
          mediaId: any(named: 'mediaId'),
          contentType: any(named: 'contentType'),
          sizeBytes: any(named: 'sizeBytes'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        )).thenAnswer((_) async {});

    final mediaId = await repository.uploadImage(
      ownerId: 'user-1',
      fileName: 'a.jpg',
      contentType: 'image/jpeg',
      bytes: bytes,
      width: 800,
      height: 600,
    );

    expect(mediaId, 'media-1');
    final request = verify(() => client.post<UploadTicket>(
          '/media/uploads',
          data: captureAny(named: 'data'),
          parse: any(named: 'parse'),
        )).captured.single as Map<String, dynamic>;
    expect(request, {
      'purpose': 'CHAT_IMAGE',
      'ownerType': 'USER',
      'ownerId': 'user-1',
      'fileName': 'a.jpg',
      'contentType': 'image/jpeg',
      'sizeBytes': 4,
    });
    verify(() => uploads.uploadBytes('https://storage/put', bytes, 'image/jpeg')).called(1);
    verify(() => uploads.completeUpload(
          mediaId: 'media-1',
          contentType: 'image/jpeg',
          sizeBytes: 4,
          width: 800,
          height: 600,
        )).called(1);
  });

  test('the cursors and the unread count use their own endpoints', () async {
    when(() => client.post<void>(any(), data: any(named: 'data'))).thenAnswer((_) async {});
    when(() => client.get<int>('/chats/unread-count', parse: any(named: 'parse')))
        .thenAnswer((invocation) async => parserOf<int>(invocation)({'chatsUnread': 4}));

    await repository.markDelivered('t1', 5);
    await repository.markRead('t1', 6);

    verify(() => client.post<void>('/chats/t1/delivered', data: {'upToSeq': 5})).called(1);
    verify(() => client.post<void>('/chats/t1/read', data: {'upToSeq': 6})).called(1);
    expect(await repository.unreadCount(), 4);
  });
}
