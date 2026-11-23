import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/calls/data/call_permissions.dart';
import 'package:valuex_mobile/features/calls/data/call_repository.dart';
import 'package:valuex_mobile/features/calls/domain/call.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';
import 'package:valuex_mobile/features/chat/presentation/chat_thread_screen.dart';
import 'package:valuex_mobile/features/communication_safety/data/communication_safety_repository.dart';
import 'package:valuex_mobile/features/communication_safety/domain/communication_safety.dart';
import 'package:valuex_mobile/features/listing/data/photo_source.dart';
import 'package:valuex_mobile/features/listing/domain/listing_photo.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/fonts.dart';
import '../../core/realtime/realtime_fakes.dart';
import '../calls/call_fixtures.dart';
import '../communication_safety/communication_safety_fixtures.dart';
import 'chat_fixtures.dart';
import 'chat_test_app.dart';

class _FakePhotoSource implements PhotoSource {
  List<PickedPhoto> picked = [];
  PhotoInspection? inspection =
      const PhotoInspection(contentType: 'image/jpeg', width: 800, height: 600);
  Object? error;

  @override
  Future<List<PickedPhoto>> pick(PhotoSourceKind kind, {required int limit}) async {
    if (error != null) throw error!;
    return picked;
  }

  @override
  Future<PhotoInspection?> inspect(Uint8List bytes) async => inspection;
}

ApiError _business(String code, {Map<String, String> details = const {}, int status = 422}) =>
    ApiError(
        type: ApiErrorType.business,
        message: code,
        code: code,
        statusCode: status,
        details: details);

void main() {
  setUpAll(() {
    loadBrandFonts();
    registerFallbackValue(Uint8List(0));
  });

  late MockChatRepository repo;

  void stub({ChatThread? thread0, List<ChatMessage>? messages, bool hasMore = false}) {
    when(() => repo.thread('t1')).thenAnswer((_) async =>
        thread0 ?? thread(lastSeq: 4, myReadSeq: 4, otherReadSeq: 2, otherDeliveredSeq: 3));
    when(() => repo.messages('t1')).thenAnswer((_) async => page(
          messages ??
              [
                listingCard(),
                message(seq: 2, body: 'Hi, is this still available?'),
                message(
                    seq: 3, body: 'Yes it is! Are you interested?', fromMe: true, status: 'SENT'),
                message(seq: 4, body: 'Is the price negotiable?'),
              ],
          hasMore: hasMore,
        ));
  }

  setUp(() {
    repo = MockChatRepository();
    when(() => repo.markDelivered(any(), any())).thenAnswer((_) async {});
    when(() => repo.markRead(any(), any())).thenAnswer((_) async {});
    when(() => repo.unreadCount()).thenAnswer((_) async => 0);
    stub();
  });

  Future<void> pump(
    WidgetTester tester, {
    List<Override> extra = const [],
    double textScale = 1,
    Size size = const Size(390, 844),
    Map<String, Object> prefs = const {'chat_safety_banner_dismissed': true},
    Locale locale = const Locale('en'),
    FakeRealtimeClient? realtime,
  }) =>
      pumpChatApp(
        tester,
        const ChatThreadScreen(threadId: 't1'),
        repo: repo,
        overrides: extra,
        textScale: textScale,
        size: size,
        preferences: prefs,
        locale: locale,
        realtime: realtime,
      );

  testWidgets('shows the header, the listing card and the messages with times and status',
      (tester) async {
    await pump(tester);

    expect(find.text('Rajesh Kumar'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsNWidgets(2));
    expect(find.text('Hi, is this still available?'), findsOneWidget);
    expect(find.text('Yes it is! Are you interested?'), findsOneWidget);
    expect(find.textContaining('Delivered'), findsOneWidget);
    expect(find.text('Say hello to start the conversation'), findsNothing);
  });

  testWidgets('each bubble is spoken as one sentence', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(find.bySemanticsLabel(RegExp(r'^Rajesh Kumar: Hi, is this still available\?\. ')),
        findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^You: Yes it is! Are you interested\?\. .*Delivered$')),
        findsOneWidget);
    handle.dispose();
  });

  testWidgets('an empty thread invites the first message', (tester) async {
    stub(thread0: thread(lastSeq: 1), messages: [listingCard()]);
    await pump(tester);

    expect(find.text('Say hello to start the conversation'), findsOneWidget);
  });

  testWidgets('the listing title in the header opens the listing', (tester) async {
    await pump(tester);

    await tester.tap(find.text('iPhone 15 Pro Max').first);
    await tester.pumpAndSettle();

    expect(find.text('listing l1'), findsOneWidget);
  });

  testWidgets('Call and Video ring the seller when the viewer is the buyer', (tester) async {
    final calls = MockCallRepository();
    final permissions = FakeCallPermissions();
    when(() => calls.start('l1', type: CallType.voice)).thenAnswer((_) async => call());
    when(() => calls.start('l1', type: CallType.video))
        .thenAnswer((_) async => call(type: 'VIDEO'));
    await pump(tester, extra: [
      callRepositoryProvider.overrideWithValue(calls),
      callPermissionsProvider.overrideWithValue(permissions),
    ]);

    await tester.tap(find.byIcon(Icons.call_outlined));
    await tester.pumpAndSettle();
    expect(find.text('call c1'), findsOneWidget);
    expect(permissions.requests, [false]);

    final router = GoRouter.of(tester.element(find.text('call c1')));
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.videocam_outlined));
    await tester.pumpAndSettle();

    expect(find.text('call c1'), findsOneWidget);
    expect(permissions.requests, [false, true]);
  });

  testWidgets('Call and Video are off for the seller of the listing', (tester) async {
    final handle = tester.ensureSemantics();
    stub(thread0: thread(role: 'SELLER', lastSeq: 4, myReadSeq: 4));
    await pump(tester);

    await tester.tap(find.byIcon(Icons.call_outlined));
    await tester.pump();

    expect(find.text('call c1'), findsNothing);
    final call = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.call_outlined));
    final video =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.videocam_outlined));
    expect(call.onPressed, isNull);
    expect(video.onPressed, isNull);
    handle.dispose();
  });

  testWidgets('the safety banner shows once and stays dismissed', (tester) async {
    await pump(tester, prefs: const {});

    expect(find.textContaining('Keep chats and payments on JustQlic'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss safety tip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Keep chats and payments on JustQlic'), findsNothing);

    await pump(tester, prefs: const {'chat_safety_banner_dismissed': true});
    expect(find.textContaining('Keep chats and payments on JustQlic'), findsNothing);
  });

  testWidgets('sending shows the message at once and the stored one replaces it', (tester) async {
    when(() => repo.sendText('t1',
            clientMessageId: any(named: 'clientMessageId'), body: 'Thanks', agreed: false))
        .thenAnswer((_) async => message(seq: 5, body: 'Thanks', fromMe: true, status: 'SENT'));
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Thanks');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Thanks'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    verify(() => repo.sendText('t1',
        clientMessageId: any(named: 'clientMessageId'), body: 'Thanks', agreed: false)).called(1);
  });

  testWidgets('Send does nothing while the field is empty', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    verifyNever(() => repo.sendText(any(),
        clientMessageId: any(named: 'clientMessageId'),
        body: any(named: 'body'),
        agreed: any(named: 'agreed')));
  });

  testWidgets('a message that cannot be sent keeps a Retry and the same message is sent again',
      (tester) async {
    var fail = true;
    when(() => repo.sendText('t1',
        clientMessageId: any(named: 'clientMessageId'),
        body: 'Hello',
        agreed: false)).thenAnswer((_) async {
      if (fail) throw const ApiError(type: ApiErrorType.network, message: 'offline');
      return message(seq: 5, body: 'Hello', fromMe: true, status: 'SENT');
    });
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Not sent. Tap to retry'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Not sent. Tap to retry'), findsNothing);
    final ids = verify(() => repo.sendText('t1',
        clientMessageId: captureAny(named: 'clientMessageId'),
        body: 'Hello',
        agreed: false)).captured;
    expect(ids, hasLength(2));
    expect(ids[0], ids[1]);
  });

  testWidgets('a failed message can be deleted', (tester) async {
    when(() => repo.sendText(any(),
            clientMessageId: any(named: 'clientMessageId'),
            body: any(named: 'body'),
            agreed: any(named: 'agreed')))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('a refused message goes back to the field with the reason', (tester) async {
    when(() => repo.sendText(any(),
        clientMessageId: any(named: 'clientMessageId'),
        body: any(named: 'body'),
        agreed: any(named: 'agreed'))).thenThrow(_business('RATE_LIMIT_EXCEEDED', status: 429));
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text("You're sending messages too fast. Slow down a little"), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Hello');
  });

  group('restricted terms (decision D13)', () {
    void blockFirst() {
      when(() => repo.sendText('t1',
              clientMessageId: any(named: 'clientMessageId'), body: 'you shit', agreed: false))
          .thenThrow(_business('WARNING_CONTENT_FLAGGED',
              details: {'terms': '4-8', 'agreementVersion': 'policy-override-v1'}));
    }

    Future<void> sendBlocked(WidgetTester tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'you shit');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
    }

    testWidgets('the alert shows the text and the two choices; Edit returns it to the field',
        (tester) async {
      blockFirst();
      await sendBlocked(tester);

      expect(find.text('Message blocked'), findsOneWidget);
      expect(find.textContaining("We detected restricted terms in your message and blocked it."),
          findsOneWidget);
      expect(find.text('Deliver message'), findsOneWidget);
      expect(find.text('Edit message'), findsOneWidget);
      expect(find.text('you shit'), findsNothing);

      await tester.tap(find.text('Edit message'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'you shit');
      verifyNever(() => repo.sendText('t1',
          clientMessageId: any(named: 'clientMessageId'), body: any(named: 'body'), agreed: true));
    });

    testWidgets('Deliver message asks for the agreement and Cancel goes back to the alert',
        (tester) async {
      blockFirst();
      await sendBlocked(tester);

      await tester.tap(find.text('Deliver message'));
      await tester.pumpAndSettle();
      expect(find.textContaining("I am confident that I'm not violating JustQlic policies."),
          findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Message blocked'), findsOneWidget);
      verifyNever(() => repo.sendText('t1',
          clientMessageId: any(named: 'clientMessageId'), body: any(named: 'body'), agreed: true));
    });

    testWidgets('I agree and deliver sends the message again with the agreement', (tester) async {
      blockFirst();
      when(() => repo.sendText('t1',
              clientMessageId: any(named: 'clientMessageId'), body: 'you shit', agreed: true))
          .thenAnswer((_) async => message(seq: 5, body: 'you shit', fromMe: true, status: 'SENT'));
      await sendBlocked(tester);

      await tester.tap(find.text('Deliver message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I agree and deliver'));
      await tester.pumpAndSettle();

      expect(find.text('you shit'), findsOneWidget);
      verify(() => repo.sendText('t1',
          clientMessageId: any(named: 'clientMessageId'),
          body: 'you shit',
          agreed: true)).called(1);
    });

    testWidgets('when the day\'s overrides are used up the user is told so', (tester) async {
      blockFirst();
      when(() => repo.sendText('t1',
          clientMessageId: any(named: 'clientMessageId'),
          body: 'you shit',
          agreed: true)).thenThrow(_business('RATE_LIMIT_EXCEEDED', status: 429));
      await sendBlocked(tester);

      await tester.tap(find.text('Deliver message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I agree and deliver'));
      await tester.pumpAndSettle();

      expect(find.text("You've used all your overrides for today"), findsOneWidget);
    });

    testWidgets('the alert works at 200 percent text and 320 px', (tester) async {
      blockFirst();
      await pump(tester, textScale: 2, size: const Size(320, 640));
      await tester.enterText(find.byType(TextField), 'you shit');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Message blocked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a thread that became read-only shows why and no composer', (tester) async {
    stub(thread0: thread(lastSeq: 4, canSend: false, readOnlyReason: 'BLOCKED'));
    await pump(tester);

    expect(find.text("You can't send messages in this conversation."), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  for (final (reason, text) in [
    ('ACCOUNT_UNAVAILABLE', "This person is currently unavailable, so you can't send messages."),
    ('LISTING_REMOVED', 'This listing was removed, so the conversation is closed.'),
  ]) {
    testWidgets('a thread closed because of $reason says why', (tester) async {
      stub(thread0: thread(lastSeq: 4, canSend: false, readOnlyReason: reason));
      await pump(tester);

      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('a server block found while sending closes the thread', (tester) async {
    when(() => repo.sendText(any(),
        clientMessageId: any(named: 'clientMessageId'),
        body: any(named: 'body'),
        agreed: any(named: 'agreed'))).thenThrow(_business('ERROR_BLOCKED', status: 403));
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text("You can't send messages in this conversation."), findsOneWidget);
    expect(find.text("You can't contact this seller"), findsOneWidget);
  });

  testWidgets('a conversation that cannot be loaded shows an error and Retry', (tester) async {
    var fail = true;
    when(() => repo.thread('t1')).thenAnswer((_) async {
      if (fail) throw const ApiError(type: ApiErrorType.network, message: 'offline');
      return thread(lastSeq: 4);
    });
    await pump(tester);
    expect(find.text('Unable to load this conversation. Try again'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, is this still available?'), findsOneWidget);
  });

  testWidgets('earlier messages are loaded on request', (tester) async {
    stub(messages: [message(seq: 4, body: 'Latest')], hasMore: true);
    when(() => repo.messages('t1', beforeSeq: 4))
        .thenAnswer((_) async => page([message(seq: 3, body: 'Earlier')]));
    await pump(tester);

    await tester.scrollUntilVisible(find.text('Load earlier messages'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Load earlier messages'));
    await tester.pumpAndSettle();

    expect(find.text('Earlier', skipOffstage: false), findsOneWidget);
  });

  testWidgets('a picture is chosen, uploaded and sent', (tester) async {
    final source = _FakePhotoSource()
      ..picked = [
        PickedPhoto(name: 'a.jpg', bytes: Uint8List.fromList([1, 2, 3]))
      ];
    when(() => repo.uploadImage(
          ownerId: any(named: 'ownerId'),
          fileName: any(named: 'fileName'),
          contentType: any(named: 'contentType'),
          bytes: any(named: 'bytes'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        )).thenAnswer((_) async => 'media-1');
    when(() => repo.sendImage('t1',
            clientMessageId: any(named: 'clientMessageId'), mediaId: 'media-1'))
        .thenAnswer((_) async => message(seq: 5, type: 'IMAGE', fromMe: true, status: 'SENT'));
    registerFallbackValue(Uint8List(0));
    await pump(tester, extra: [chatPhotoSourceProvider.overrideWithValue(source), _profile()]);

    await tester.tap(find.byTooltip('Attach a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    verify(() => repo.sendImage('t1',
        clientMessageId: any(named: 'clientMessageId'), mediaId: 'media-1')).called(1);
  });

  testWidgets('a picture the app cannot read is refused before any upload', (tester) async {
    final source = _FakePhotoSource()
      ..picked = [PickedPhoto(name: 'a.bin', bytes: Uint8List(2))]
      ..inspection = null;
    await pump(tester, extra: [chatPhotoSourceProvider.overrideWithValue(source)]);

    await tester.tap(find.byTooltip('Attach a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text("This image can't be sent"), findsOneWidget);
    verifyNever(() => repo.sendImage(any(),
        clientMessageId: any(named: 'clientMessageId'), mediaId: any(named: 'mediaId')));
  });

  testWidgets('a refused camera or photo permission is explained', (tester) async {
    final source = _FakePhotoSource()
      ..error = const PhotoAccessDeniedException(PhotoSourceKind.camera);
    await pump(tester, extra: [chatPhotoSourceProvider.overrideWithValue(source)]);

    await tester.tap(find.byTooltip('Attach a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text('Allow access to your camera or photos in Settings to share a picture'),
        findsOneWidget);
  });

  group('live connection', () {
    testWidgets('shows a message that arrives as an event, and the other person typing',
        (tester) async {
      final realtime = FakeRealtimeClient();
      await pump(tester, realtime: realtime);

      realtime.emit('chat.typing', {'threadId': 't1', 'typing': true});
      await tester.pumpAndSettle();
      expect(find.text('Rajesh Kumar is typing…'), findsOneWidget);

      realtime.emit('chat.message.created', {
        'threadId': 't1',
        'message': messageJson(seq: 5, body: 'Live hello'),
      });
      await tester.pumpAndSettle();

      expect(find.text('Live hello'), findsOneWidget);
      expect(find.text('Rajesh Kumar is typing…'), findsNothing);
    });

    testWidgets('the typing line goes away by itself and is hidden when nobody can write',
        (tester) async {
      final realtime = FakeRealtimeClient();
      await pump(tester, realtime: realtime);

      realtime.emit('chat.typing', {'threadId': 't1', 'typing': true});
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Rajesh Kumar is typing…'), findsNothing);

      realtime.emit('chat.typing', {'threadId': 't1', 'typing': true});
      realtime.emit('chat.thread.updated', {
        'threadId': 't1',
        'canSend': false,
        'readOnlyReason': 'BLOCKED',
        'lastSeq': 4,
      });
      await tester.pumpAndSettle();
      expect(find.text('Rajesh Kumar is typing…'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('the composer tells the other person that the user is typing, and stops',
        (tester) async {
      final realtime = FakeRealtimeClient()..open = true;
      await pump(tester, realtime: realtime);

      await tester.enterText(find.byType(TextField), 'Hel');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      final typing = [
        for (final frame in realtime.sent)
          if (frame.type == 'chat.typing') frame.data!['typing'],
      ];
      expect(typing, [true, false]);
    });

    for (final status in [RealtimeStatus.reconnecting, RealtimeStatus.degraded]) {
      testWidgets('shows the reconnecting strip while $status', (tester) async {
        await pump(tester, extra: [
          realtimeStatusProvider.overrideWith(() => _FixedStatus(status)),
        ]);

        expect(find.text('Reconnecting…'), findsOneWidget);
      });
    }

    testWidgets('shows no strip while the connection is fine', (tester) async {
      await pump(tester);

      expect(find.text('Reconnecting…'), findsNothing);
    });
  });

  testWidgets('works in Hindi', (tester) async {
    await pump(tester, locale: const Locale('hi'));

    expect(find.text('संदेश लिखें...'), findsOneWidget);
  });

  testWidgets('does not overflow at 320 px and 200 percent text and meets the guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, textScale: 2, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrast));
    handle.dispose();
  });

  group('header menu', () {
    late FakeCommunicationSafetyRepository safety;

    setUp(() => safety = FakeCommunicationSafetyRepository());

    Future<void> openMenu(WidgetTester tester) async {
      await pump(
        tester,
        extra: [communicationSafetyRepositoryProvider.overrideWithValue(safety)],
      );
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
    }

    testWidgets('blocks the other person after confirmation and says so', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text('Block user'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(safety.blocked, [thread().counterpart.userId]);
      expect(find.text('User blocked'), findsOneWidget);
    });

    testWidgets('says so when blocking fails', (tester) async {
      safety.onBlock = (id) async => throw Exception('offline');
      await openMenu(tester);
      await tester.tap(find.text('Block user'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to block this user. Try again'), findsOneWidget);
    });

    testWidgets('reports the person', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text('Report user'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(safety.reports.single.target, ReportTarget.user);
      expect(safety.reports.single.targetId, thread().counterpart.userId);
      expect(find.text("Thanks. We've received your report"), findsOneWidget);
    });

    testWidgets('reports the conversation', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text('Report conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(safety.reports.single.target, ReportTarget.thread);
      expect(safety.reports.single.targetId, 't1');
    });
  });
}

class _FixedStatus extends RealtimeStatusController {
  final RealtimeStatus initial;

  _FixedStatus(this.initial);

  @override
  RealtimeStatus build() => initial;
}

Override _profile() => userProfileProvider.overrideWith((ref) async => const UserProfile(
      userId: 'me',
      status: AccountStatus.active,
      aadhaarVerified: true,
    ));
