import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/chat/data/chat_repository.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_launcher.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_list_controller.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_polling.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_thread_controller.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_unread_provider.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';

import 'chat_fixtures.dart';

ApiError _business(String code, {Map<String, String> details = const {}, int status = 422}) =>
    ApiError(
        type: ApiErrorType.business,
        message: code,
        code: code,
        statusCode: status,
        details: details);

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

void main() {
  late MockChatRepository repo;

  setUpAll(() {
    registerFallbackValue(ChatRole.all);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repo = MockChatRepository();
    when(() => repo.markDelivered(any(), any())).thenAnswer((_) async {});
    when(() => repo.markRead(any(), any())).thenAnswer((_) async {});
  });

  ProviderContainer container({Duration? poll, List<Override> extra = const []}) {
    final created = ProviderContainer(overrides: [
      chatRepositoryProvider.overrideWithValue(repo),
      chatPollIntervalProvider.overrideWithValue(poll),
      userProfileProvider.overrideWith((ref) async => const UserProfile(
            userId: 'me',
            status: AccountStatus.active,
            aadhaarVerified: true,
          )),
      ...extra,
    ]);
    addTearDown(created.dispose);
    return created;
  }

  group('thread controller', () {
    void stubThread({
      ChatThread? thread,
      List<ChatMessage>? messages,
      bool hasMore = false,
    }) {
      when(() => repo.thread('t1')).thenAnswer((_) async => thread ?? _thread());
      when(() => repo.messages('t1')).thenAnswer((_) async => page(
            messages ?? [listingCard(), message(seq: 2, body: 'Hi', fromMe: true, status: 'SENT')],
            hasMore: hasMore,
          ));
    }

    Future<ChatThreadController> open(ProviderContainer c) async {
      c.listen(chatThreadControllerProvider('t1'), (_, __) {});
      await c.read(chatThreadControllerProvider('t1').future);
      return c.read(chatThreadControllerProvider('t1').notifier);
    }

    ChatThreadState current(ProviderContainer c) =>
        c.read(chatThreadControllerProvider('t1')).requireValue;

    test('loads the thread and the latest page, then marks what it holds as delivered and read',
        () async {
      stubThread(
        thread: _thread(lastSeq: 3, myReadSeq: 1),
        messages: [
          listingCard(),
          message(seq: 2, body: 'Hello'),
          message(seq: 3, body: 'Is it available?')
        ],
      );
      final c = container();

      await open(c);
      await Future<void>.delayed(Duration.zero);

      expect(current(c).messages.map((m) => m.seq), [1, 2, 3]);
      expect(current(c).firstUnreadSeq, 2);
      verify(() => repo.markDelivered('t1', 3)).called(1);
      verify(() => repo.markRead('t1', 3)).called(1);
    });

    test('marks nothing when everything was already read', () async {
      stubThread(thread: _thread(lastSeq: 2, myReadSeq: 2));
      final c = container();

      await open(c);
      await Future<void>.delayed(Duration.zero);

      expect(current(c).firstUnreadSeq, 0);
      verifyNever(() => repo.markRead(any(), any()));
    });

    test('a message shows as sending at once and is replaced by the stored one', () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      final gate = Completer<ChatMessage>();
      when(() => repo.sendText('t1',
          clientMessageId: any(named: 'clientMessageId'),
          body: 'Hello',
          agreed: false)).thenAnswer((_) => gate.future);

      final outcome = controller.sendText('  Hello  ');

      expect(current(c).messages.last.status, MessageStatus.sending);
      expect(current(c).messages.last.seq, 0);
      expect(current(c).messages.last.body, 'Hello');
      gate.complete(message(seq: 3, body: 'Hello', fromMe: true, status: 'SENT'));
      expect(await outcome, isA<SendStored>());
      expect(current(c).messages.map((m) => m.seq), [1, 2, 3]);
      expect(current(c).messages.last.status, MessageStatus.sent);
    });

    test('a blocked message is taken out and comes back with the ranges to highlight', () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      when(() => repo.sendText('t1',
              clientMessageId: any(named: 'clientMessageId'), body: 'you shit', agreed: false))
          .thenThrow(_business('WARNING_CONTENT_FLAGGED',
              details: {'terms': '4-8', 'agreementVersion': 'v1'}));

      final outcome = await controller.sendText('you shit');

      expect(outcome, isA<SendFlagged>());
      final flagged = outcome as SendFlagged;
      expect(flagged.body, 'you shit');
      expect(flagged.terms.single.start, 4);
      expect(flagged.terms.single.end, 8);
      expect(current(c).messages.any((m) => m.seq == 0), isFalse);
    });

    test('delivering a blocked message sends the same client id again with the agreement',
        () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      when(() => repo.sendText('t1', clientMessageId: 'c-1', body: 'you shit', agreed: true))
          .thenAnswer((_) async => message(seq: 3, body: 'you shit', fromMe: true, status: 'SENT'));

      final outcome = await controller.sendText('you shit', clientMessageId: 'c-1', agreed: true);

      expect(outcome, isA<SendStored>());
      expect(current(c).messages.last.seq, 3);
    });

    test('a refusal that stores nothing removes the message and returns the error', () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      when(() => repo.sendText(any(),
          clientMessageId: any(named: 'clientMessageId'),
          body: any(named: 'body'),
          agreed: any(named: 'agreed'))).thenThrow(_business('RATE_LIMIT_EXCEEDED', status: 429));

      final outcome = await controller.sendText('Hello');

      expect(outcome, isA<SendRefused>());
      expect((outcome as SendRefused).error, isA<ApiError>());
      expect(current(c).messages.any((m) => m.seq == 0), isFalse);
      expect(current(c).thread.canSend, isTrue);
    });

    test('a block, a closed listing or an unavailable person turn the thread read-only', () async {
      for (final (code, reason) in [
        ('ERROR_BLOCKED', ReadOnlyReason.blocked),
        ('ERROR_THREAD_READ_ONLY', ReadOnlyReason.listingRemoved),
        ('ERROR_SELLER_UNAVAILABLE', ReadOnlyReason.accountUnavailable),
      ]) {
        stubThread();
        final c = container();
        final controller = await open(c);
        when(() => repo.sendText(any(),
            clientMessageId: any(named: 'clientMessageId'),
            body: any(named: 'body'),
            agreed: any(named: 'agreed'))).thenThrow(_business(code, status: 403));

        await controller.sendText('Hello');

        expect(current(c).thread.canSend, isFalse, reason: code);
        expect(current(c).thread.readOnlyReason, reason);
      }
    });

    test('a lost connection keeps the message as failed and a retry sends the same client id',
        () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      final ids = <String>[];
      var fail = true;
      when(() => repo.sendText('t1',
          clientMessageId: any(named: 'clientMessageId'),
          body: 'Hello',
          agreed: false)).thenAnswer((invocation) async {
        ids.add(invocation.namedArguments[#clientMessageId] as String);
        if (fail) throw _offline;
        return message(seq: 3, body: 'Hello', fromMe: true, status: 'SENT');
      });

      expect(await controller.sendText('Hello'), isA<SendQueued>());
      expect(current(c).messages.last.status, MessageStatus.failed);
      fail = false;
      expect(await controller.retry(current(c).messages.last.clientMessageId), isA<SendStored>());

      expect(ids.toSet(), hasLength(1));
      expect(current(c).messages.last.seq, 3);
      expect(current(c).messages.any((m) => m.isPending), isFalse);
    });

    test('retrying something that is not failed does nothing, and discard removes a failed message',
        () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      when(() => repo.sendText(any(),
          clientMessageId: any(named: 'clientMessageId'),
          body: any(named: 'body'),
          agreed: any(named: 'agreed'))).thenThrow(_offline);
      await controller.sendText('Hello');
      final id = current(c).messages.last.clientMessageId;

      expect(await controller.retry('unknown'), isA<SendStored>());
      controller.discard(id);

      expect(current(c).messages.any((m) => m.isPending), isFalse);
    });

    test('a picture is uploaded once even when sending the message has to be retried', () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      var uploads = 0;
      var fail = true;
      when(() => repo.uploadImage(
            ownerId: any(named: 'ownerId'),
            fileName: any(named: 'fileName'),
            contentType: any(named: 'contentType'),
            bytes: any(named: 'bytes'),
            width: any(named: 'width'),
            height: any(named: 'height'),
          )).thenAnswer((_) async {
        uploads++;
        return 'media-1';
      });
      when(() => repo.sendImage('t1',
          clientMessageId: any(named: 'clientMessageId'),
          mediaId: 'media-1')).thenAnswer((_) async {
        if (fail) throw _offline;
        return message(seq: 3, fromMe: true, type: 'IMAGE', status: 'SENT');
      });

      final outcome = await controller.sendImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'a.jpg',
        contentType: 'image/jpeg',
        width: 10,
        height: 10,
      );
      expect(outcome, isA<SendQueued>());
      expect(current(c).messages.last.pendingImage, isNotNull);
      fail = false;
      await controller.retry(current(c).messages.last.clientMessageId);

      expect(uploads, 1);
      expect(current(c).messages.last.seq, 3);
      verify(() => repo.uploadImage(
            ownerId: 'me',
            fileName: 'a.jpg',
            contentType: 'image/jpeg',
            bytes: any(named: 'bytes'),
            width: 10,
            height: 10,
          )).called(1);
    });

    test('a picture the server refuses is removed and its error returned', () async {
      stubThread();
      final c = container();
      final controller = await open(c);
      when(() => repo.uploadImage(
            ownerId: any(named: 'ownerId'),
            fileName: any(named: 'fileName'),
            contentType: any(named: 'contentType'),
            bytes: any(named: 'bytes'),
            width: any(named: 'width'),
            height: any(named: 'height'),
          )).thenAnswer((_) async => 'media-2');
      when(() => repo.sendImage('t1',
          clientMessageId: any(named: 'clientMessageId'),
          mediaId: 'media-2')).thenThrow(_business('ERROR_IMAGE_TOO_LARGE'));

      final outcome = await controller.sendImage(
        bytes: Uint8List(2),
        fileName: 'b.jpg',
        contentType: 'image/jpeg',
        width: 1,
        height: 1,
      );

      expect(outcome, isA<SendRefused>());
      expect(current(c).messages.any((m) => m.seq == 0), isFalse);
    });

    test('a poll adds what arrived, updates the status of my messages and marks it read', () async {
      stubThread(thread: _thread(lastSeq: 2, myReadSeq: 2));
      final c = container(poll: const Duration(milliseconds: 30));
      await open(c);
      when(() => repo.thread('t1'))
          .thenAnswer((_) async => _thread(lastSeq: 3, myReadSeq: 2, otherReadSeq: 2));
      when(() => repo.messages('t1', afterSeq: 2))
          .thenAnswer((_) async => page([message(seq: 3, body: 'Yes it is')]));

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(current(c).messages.map((m) => m.seq), [1, 2, 3]);
      expect(current(c).messages[1].status, MessageStatus.read);
      verify(() => repo.markRead('t1', 3)).called(greaterThanOrEqualTo(1));
    });

    test('a poll that fails changes nothing, and a good one retries what was queued', () async {
      stubThread();
      final c = container(poll: const Duration(milliseconds: 30));
      final controller = await open(c);
      var fail = true;
      when(() => repo.sendText('t1',
          clientMessageId: any(named: 'clientMessageId'),
          body: 'Hello',
          agreed: false)).thenAnswer((_) async {
        if (fail) throw _offline;
        return message(seq: 3, body: 'Hello', fromMe: true, status: 'SENT');
      });
      await controller.sendText('Hello');
      when(() => repo.thread('t1')).thenThrow(_offline);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(current(c).messages.last.status, MessageStatus.failed);

      fail = false;
      when(() => repo.thread('t1')).thenAnswer((_) async => _thread());
      when(() => repo.messages('t1', afterSeq: 2)).thenAnswer((_) async => page(const []));
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(current(c).messages.last.seq, 3);
    });

    test('loads older messages in front of the ones it has, and says when that fails', () async {
      stubThread(messages: [message(seq: 5), message(seq: 6)], hasMore: true);
      final c = container();
      final controller = await open(c);
      when(() => repo.messages('t1', beforeSeq: 5))
          .thenAnswer((_) async => page([message(seq: 3), message(seq: 4)], hasMore: false));

      expect(await controller.loadOlder(), isTrue);

      expect(current(c).messages.map((m) => m.seq), [3, 4, 5, 6]);
      expect(current(c).hasMoreOlder, isFalse);
      expect(await controller.loadOlder(), isTrue);
    });

    test('a failed load of older messages returns false and allows another try', () async {
      stubThread(messages: [message(seq: 5)], hasMore: true);
      final c = container();
      final controller = await open(c);
      when(() => repo.messages('t1', beforeSeq: 5)).thenThrow(_offline);

      expect(await controller.loadOlder(), isFalse);
      expect(current(c).loadingOlder, isFalse);
      expect(current(c).hasMoreOlder, isTrue);
    });

    test('shows the error state when the thread cannot be loaded', () async {
      when(() => repo.thread('t1')).thenThrow(_offline);
      when(() => repo.messages('t1')).thenAnswer((_) async => page(const []));
      final c = container();
      c.listen(chatThreadControllerProvider('t1'), (_, __) {});

      await expectLater(
          c.read(chatThreadControllerProvider('t1').future), throwsA(isA<ApiError>()));
    });
  });

  group('chat list controller', () {
    Future<void> load(ProviderContainer c) async {
      c.listen(chatListControllerProvider, (_, __) {});
      await c.read(chatListControllerProvider.future);
    }

    ChatListState state(ProviderContainer c) => c.read(chatListControllerProvider).requireValue;

    test('loads the first page for the selected side and reloads when the side changes', () async {
      when(() => repo.threads(role: ChatRole.all, page: any(named: 'page')))
          .thenAnswer((_) async => threadPage([_thread(id: 'a'), _thread(id: 'b')], hasNext: true));
      when(() => repo.threads(role: ChatRole.selling, page: any(named: 'page')))
          .thenAnswer((_) async => threadPage([_thread(id: 's', role: 'SELLER')]));
      final c = container();
      await load(c);
      expect(state(c).threads.map((t) => t.threadId), ['a', 'b']);
      expect(state(c).hasNext, isTrue);

      c.read(chatRoleFilterProvider.notifier).select(ChatRole.selling);
      await c.read(chatListControllerProvider.future);

      expect(state(c).threads.map((t) => t.threadId), ['s']);
    });

    test('loadMore appends the next page without repeating a thread', () async {
      when(() => repo.threads(role: ChatRole.all, page: 0))
          .thenAnswer((_) async => threadPage([_thread(id: 'a')], hasNext: true));
      when(() => repo.threads(role: ChatRole.all, page: 1))
          .thenAnswer((_) async => threadPage([_thread(id: 'a'), _thread(id: 'b')], page: 1));
      final c = container();
      await load(c);

      expect(await c.read(chatListControllerProvider.notifier).loadMore(), isTrue);

      expect(state(c).threads.map((t) => t.threadId), ['a', 'b']);
      expect(state(c).hasNext, isFalse);
      expect(await c.read(chatListControllerProvider.notifier).loadMore(), isTrue);
    });

    test('a failed loadMore returns false and keeps the list', () async {
      when(() => repo.threads(role: ChatRole.all, page: 0))
          .thenAnswer((_) async => threadPage([_thread(id: 'a')], hasNext: true));
      when(() => repo.threads(role: ChatRole.all, page: 1)).thenThrow(_offline);
      final c = container();
      await load(c);

      expect(await c.read(chatListControllerProvider.notifier).loadMore(), isFalse);

      expect(state(c).threads, hasLength(1));
      expect(state(c).loadingMore, isFalse);
    });

    test('refresh replaces the list', () async {
      var round = 0;
      when(() => repo.threads(role: ChatRole.all, page: any(named: 'page')))
          .thenAnswer((_) async => threadPage([_thread(id: 'r${round++}')]));
      final c = container();
      await load(c);

      await c.read(chatListControllerProvider.notifier).refresh();

      expect(state(c).threads.single.threadId, 'r1');
    });

    test(
        'a poll puts fresh threads first and keeps the pages already loaded; a failed poll changes nothing',
        () async {
      var calls = 0;
      when(() => repo.threads(role: ChatRole.all, page: any(named: 'page'))).thenAnswer((_) async {
        calls++;
        if (calls == 1) return threadPage([_thread(id: 'a')]);
        if (calls == 2) throw _offline;
        return threadPage([_thread(id: 'z'), _thread(id: 'a', unread: 4)]);
      });
      final c = container(poll: const Duration(milliseconds: 30));
      await load(c);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(state(c).threads.map((t) => t.threadId), ['z', 'a']);
      expect(state(c).threads.last.unreadCount, 4);
    });

    test('an unread count shows the dot, and a failed first read shows none', () async {
      when(() => repo.unreadCount()).thenAnswer((_) async => 2);
      final c = container();
      c.listen(chatsHasUnreadProvider, (_, __) {});
      await c.read(chatUnreadCountProvider.future);
      expect(c.read(chatsHasUnreadProvider), isTrue);

      when(() => repo.unreadCount()).thenThrow(_offline);
      final failing = container();
      failing.listen(chatsHasUnreadProvider, (_, __) {});
      await expectLater(failing.read(chatUnreadCountProvider.future), throwsA(isA<ApiError>()));
      expect(failing.read(chatsHasUnreadProvider), isFalse);
    });
  });

  group('chat launcher', () {
    test('a thread the page already knows is opened without a request', () async {
      final c = container();

      final result = await c.read(chatLauncherProvider.notifier).open('l1', knownThreadId: 't9');

      expect(result.threadId, 't9');
      verifyNever(() => repo.open(any()));
    });

    test('opens a new chat and ignores a second tap while the request runs', () async {
      final gate = Completer<OpenedChat>();
      when(() => repo.open('l1')).thenAnswer((_) => gate.future);
      final c = container();
      c.listen(chatLauncherProvider, (_, __) {});
      final launcher = c.read(chatLauncherProvider.notifier);

      final first = launcher.open('l1');
      expect(c.read(chatLauncherProvider), isTrue);
      final second = await launcher.open('l1');
      gate.complete(OpenedChat(thread: _thread(id: 'new'), created: true));

      expect(second.threadId, isNull);
      expect(second.error, isNull);
      expect((await first).threadId, 'new');
      expect(c.read(chatLauncherProvider), isFalse);
      verify(() => repo.open('l1')).called(1);
    });

    test('a refusal comes back as the error', () async {
      when(() => repo.open('l1')).thenThrow(_business('ERROR_BLOCKED', status: 403));
      final c = container();

      final result = await c.read(chatLauncherProvider.notifier).open('l1');

      expect(result.threadId, isNull);
      expect((result.error as ApiError).code, 'ERROR_BLOCKED');
    });
  });
}

ChatThread _thread(
        {String id = 't1',
        String role = 'BUYER',
        int unread = 0,
        int lastSeq = 2,
        int myReadSeq = 0,
        int otherReadSeq = 0,
        int otherDeliveredSeq = 0}) =>
    thread(
      id: id,
      role: role,
      unread: unread,
      lastSeq: lastSeq,
      myReadSeq: myReadSeq,
      otherReadSeq: otherReadSeq,
      otherDeliveredSeq: otherDeliveredSeq,
    );
