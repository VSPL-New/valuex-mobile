import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';
import 'package:valuex_mobile/features/chat/presentation/chat_list_screen.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_unread_provider.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/fonts.dart';
import 'chat_fixtures.dart';
import 'chat_test_app.dart';

void main() {
  setUpAll(() {
    loadBrandFonts();
    registerFallbackValue(ChatRole.all);
  });

  late MockChatRepository repo;

  final rows = [
    thread(
      id: 't1',
      counterpart: 'Rajesh Kumar',
      listingTitle: 'iPhone 15 Pro Max',
      unread: 2,
      lastMessage: {
        'type': 'TEXT',
        'preview': 'Is the price negotiable?',
        'at': DateTime.now().subtract(const Duration(minutes: 2)).toUtc().toIso8601String(),
        'fromMe': false,
      },
    ),
    thread(
      id: 't2',
      role: 'SELLER',
      counterpart: 'Priya Sharma',
      listingTitle: 'MacBook Pro 14"',
      lastMessage: {
        'type': 'TEXT',
        'preview': "I'd like to see the product",
        'at': DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String(),
        'fromMe': true,
      },
    ),
    thread(id: 't3', counterpart: 'Amit Patel', listingTitle: 'Sony Camera'),
  ];

  setUp(() {
    repo = MockChatRepository();
    when(() => repo.threads(role: any(named: 'role'), page: any(named: 'page')))
        .thenAnswer((_) async => threadPage(rows));
    when(() => repo.unreadCount()).thenAnswer((_) async => 2);
  });

  Future<void> pump(WidgetTester tester,
          {double textScale = 1, Size size = const Size(390, 844)}) =>
      pumpChatApp(tester, const ChatListScreen(), repo: repo, textScale: textScale, size: size);

  testWidgets('lists the conversations with name, listing, preview, time, unread count and tag',
      (tester) async {
    await pump(tester);

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Rajesh Kumar'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
    expect(find.text('Is the price negotiable?'), findsOneWidget);
    expect(find.text('2m ago'), findsOneWidget);
    expect(find.text('1h ago'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('You: I\'d like to see the product'), findsOneWidget);
    expect(find.text('No messages yet'), findsOneWidget);
    expect(find.text('Buying'), findsNWidgets(3));
    expect(find.text('Selling'), findsNWidgets(2));
  });

  testWidgets('each row is spoken as one sentence with its unread count', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(
      find.bySemanticsLabel(RegExp(
          r'Rajesh Kumar, about iPhone 15 Pro Max\. Is the price negotiable\?\. 2m ago\. 2 unread')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the Chats tab is current and the dot follows the unread count', (tester) async {
    await pump(tester);

    expect(find.text('Chats'), findsOneWidget);
    expect(find.byType(ChatListScreen), findsOneWidget);
  });

  testWidgets('search filters by the name or the listing title and never by message text',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'priya');
    await tester.pump();
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Rajesh Kumar'), findsNothing);

    await tester.enterText(find.byType(TextField), 'camera');
    await tester.pump();
    expect(find.text('Amit Patel'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsNothing);

    await tester.enterText(find.byType(TextField), 'negotiable');
    await tester.pump();
    expect(find.text('No conversations match your search'), findsOneWidget);
  });

  testWidgets('the Buying and Selling chips ask the server for that side', (tester) async {
    await pump(tester);
    when(() => repo.threads(role: ChatRole.selling, page: any(named: 'page')))
        .thenAnswer((_) async => threadPage([rows[1]]));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Selling'));
    await tester.pumpAndSettle();

    verify(() => repo.threads(role: ChatRole.selling, page: any(named: 'page'))).called(1);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Rajesh Kumar'), findsNothing);
  });

  testWidgets('an empty list tells the user where to start', (tester) async {
    when(() => repo.threads(role: any(named: 'role'), page: any(named: 'page')))
        .thenAnswer((_) async => threadPage(const []));
    await pump(tester);

    expect(find.text('No conversations yet'), findsOneWidget);
    expect(find.text('Start from a listing.'), findsOneWidget);
  });

  testWidgets('a failed load shows an error and Retry loads again', (tester) async {
    var fail = true;
    when(() => repo.threads(role: any(named: 'role'), page: any(named: 'page')))
        .thenAnswer((_) async {
      if (fail) throw const ApiError(type: ApiErrorType.network, message: 'offline');
      return threadPage(rows);
    });
    await pump(tester);
    expect(find.text('Unable to load your conversations. Try again'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Rajesh Kumar'), findsOneWidget);
  });

  testWidgets('a tap on a row opens its conversation', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Rajesh Kumar'));
    await tester.pumpAndSettle();

    expect(find.text('thread t1'), findsOneWidget);
  });

  testWidgets('a next page is offered and loaded', (tester) async {
    when(() => repo.threads(role: ChatRole.all, page: 0))
        .thenAnswer((_) async => threadPage(rows.take(2).toList(), hasNext: true));
    when(() => repo.threads(role: ChatRole.all, page: 1))
        .thenAnswer((_) async => threadPage([rows[2]], page: 1));
    await pump(tester);

    await tester.tap(find.text('Load earlier messages'));
    await tester.pumpAndSettle();

    expect(find.text('Amit Patel'), findsOneWidget);
  });

  testWidgets('a failed next page says so', (tester) async {
    when(() => repo.threads(role: ChatRole.all, page: 0))
        .thenAnswer((_) async => threadPage(rows.take(2).toList(), hasNext: true));
    when(() => repo.threads(role: ChatRole.all, page: 1))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    await pump(tester);

    await tester.tap(find.text('Load earlier messages'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load more conversations. Try again'), findsOneWidget);
  });

  testWidgets('works in Hindi', (tester) async {
    await pumpChatApp(tester, const ChatListScreen(), repo: repo, locale: const Locale('hi'));

    expect(find.text('संदेश'), findsOneWidget);
    expect(find.text('बातचीत खोजें...'), findsOneWidget);
  });

  testWidgets('does not overflow at 320 px wide and 200 percent text, and meets the guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, textScale: 2, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrast));
    handle.dispose();
  });

  testWidgets('the unread provider is read by the tab', (tester) async {
    await pump(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(ChatListScreen)));
    expect(await container.read(chatUnreadCountProvider.future), 2);
  });
}
