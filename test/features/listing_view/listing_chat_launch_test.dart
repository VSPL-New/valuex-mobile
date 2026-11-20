import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/chat/data/chat_repository.dart';
import 'package:valuex_mobile/features/listing_view/data/listing_view_repository.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/listing_view_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';
import '../chat/chat_fixtures.dart';

class _MockListingViewRepository extends Mock implements ListingViewRepository {}

PublicListing _listing({String? threadId, bool chatAvailable = true}) => PublicListing.fromJson({
      'listingId': 'l1',
      'title': 'Apple Watch',
      'description': 'Lightly used',
      'price': 14500,
      'seller': {'sellerId': 's1', 'displayName': 'Asha K'},
      'capabilities': {
        'chat': {'available': chatAvailable, 'reason': chatAvailable ? null : 'UNAVAILABLE'},
        'call': {'available': false, 'reason': 'COMING_SOON'},
        'video': {'available': false, 'reason': 'COMING_SOON'},
        'offer': {'available': false, 'reason': 'COMING_SOON'},
        'cart': {'available': false, 'reason': 'COMING_SOON'},
        'buyNow': {'available': false, 'reason': 'COMING_SOON'},
      },
      'contact': {'threadId': threadId},
    });

void main() {
  setUpAll(loadBrandFonts);

  late MockChatRepository chats;
  late _MockListingViewRepository listings;

  setUp(() {
    chats = MockChatRepository();
    listings = _MockListingViewRepository();
  });

  Future<void> open(WidgetTester tester, PublicListing listing) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(() => listings.view('l1')).thenAnswer((_) async => listing);
    final router = GoRouter(
      initialLocation: '/listing/l1',
      routes: [
        GoRoute(
          path: RouteNames.listingViewPattern,
          builder: (context, state) =>
              ListingViewScreen(listingId: state.pathParameters['listingId']!),
        ),
        GoRoute(
          path: RouteNames.chatThreadPattern,
          builder: (context, state) => Scaffold(
            body: Column(children: [
              Text('thread ${state.pathParameters['threadId']}'),
              TextButton(onPressed: () => context.pop(), child: const Text('back')),
            ]),
          ),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        listingViewRepositoryProvider.overrideWithValue(listings),
        chatRepositoryProvider.overrideWithValue(chats),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping Chat starts the chat and opens the conversation', (tester) async {
    when(() => chats.open('l1'))
        .thenAnswer((_) async => OpenedChat(thread: thread(id: 'new'), created: true));
    await open(tester, _listing());

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('thread new'), findsOneWidget);
    verify(() => chats.open('l1')).called(1);
  });

  testWidgets('a chat that already exists opens straight away and the button reads Chat',
      (tester) async {
    await open(tester, _listing(threadId: 't7'));
    expect(find.text('Chat'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('thread t7'), findsOneWidget);
    verifyNever(() => chats.open(any()));
  });

  testWidgets('after coming back the listing is read again and the chat opens straight away',
      (tester) async {
    when(() => chats.open('l1'))
        .thenAnswer((_) async => OpenedChat(thread: thread(id: 'new'), created: true));
    await open(tester, _listing());

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    when(() => listings.view('l1')).thenAnswer((_) async => _listing(threadId: 'new'));
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Open chat'), findsNothing);
  });

  testWidgets('every refusal shows its own message and stays on the listing', (tester) async {
    for (final (code, status, text) in [
      ('ERROR_BLOCKED', 403, 'You cannot contact this seller'),
      ('ERROR_SELLER_UNAVAILABLE', 409, 'Seller is currently unavailable'),
      ('WARNING_RATE_LIMIT', 429, 'Too many contact attempts. Try again later'),
      ('ERROR_OWN_LISTING', 409, 'This is your own listing'),
      ('ERROR_ACCOUNT_NOT_ACTIVE', 403, 'Complete your registration to contact sellers'),
    ]) {
      when(() => chats.open('l1')).thenThrow(
          ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: status));
      await open(tester, _listing());

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.text(text), findsOneWidget, reason: code);
      expect(find.text('Apple Watch'), findsWidgets);
    }
  });

  testWidgets('a stale session gets the login message', (tester) async {
    when(() => chats.open('l1'))
        .thenThrow(const ApiError(type: ApiErrorType.unauthorized, message: 'x', statusCode: 401));
    await open(tester, _listing());

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Please login to contact seller'), findsOneWidget);
  });

  testWidgets('a listing that is gone refreshes the page after the refusal', (tester) async {
    when(() => chats.open('l1')).thenThrow(const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_LISTING_NOT_AVAILABLE',
        statusCode: 404));
    await open(tester, _listing());

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    verify(() => listings.view('l1')).called(2);
  });

  testWidgets('an unavailable seller disables Chat', (tester) async {
    await open(tester, _listing(chatAvailable: false));

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    verifyNever(() => chats.open(any()));
  });
}
