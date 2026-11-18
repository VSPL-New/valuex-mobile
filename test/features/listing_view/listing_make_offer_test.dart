import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/chat/data/chat_repository.dart';
import 'package:valuex_mobile/features/listing_view/data/listing_view_repository.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/listing_view_screen.dart';
import 'package:valuex_mobile/features/negotiation/data/negotiation_repository.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/realtime/realtime_fakes.dart';
import '../../helpers/fonts.dart';
import '../chat/chat_fixtures.dart';
import '../negotiation/negotiation_fixtures.dart';

class _MockListingViewRepository extends Mock implements ListingViewRepository {}

PublicListing _listing({
  bool offerAvailable = true,
  String offerReason = 'COMING_SOON',
  String? negotiationId,
  num? price = 14500,
  String? threadId,
}) =>
    PublicListing.fromJson({
      'listingId': 'l1',
      'title': 'Apple Watch',
      'description': 'Lightly used',
      'price': price,
      'negotiable': true,
      'seller': {'sellerId': 's1', 'displayName': 'Asha K'},
      'capabilities': {
        'chat': {'available': true},
        'call': {'available': false, 'reason': 'COMING_SOON'},
        'video': {'available': false, 'reason': 'COMING_SOON'},
        'offer': {'available': offerAvailable, 'reason': offerAvailable ? null : offerReason},
        'cart': {'available': false, 'reason': 'COMING_SOON'},
        'buyNow': {'available': false, 'reason': 'COMING_SOON'},
      },
      'contact': {'threadId': threadId, 'negotiationId': negotiationId},
    });

void main() {
  setUpAll(loadBrandFonts);

  late _MockListingViewRepository listings;
  late MockNegotiationRepository negotiations;
  late MockChatRepository chats;

  setUp(() {
    listings = _MockListingViewRepository();
    negotiations = MockNegotiationRepository();
    chats = MockChatRepository();
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
          path: RouteNames.negotiationPattern,
          builder: (context, state) => Scaffold(
            body: Column(children: [
              Text('negotiation ${state.pathParameters['negotiationId']}'),
              TextButton(onPressed: () => context.pop(), child: const Text('back')),
            ]),
          ),
        ),
        GoRoute(
          path: RouteNames.chatThreadPattern,
          builder: (context, state) =>
              Scaffold(body: Text('thread ${state.pathParameters['threadId']}')),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        listingViewRepositoryProvider.overrideWithValue(listings),
        negotiationRepositoryProvider.overrideWithValue(negotiations),
        chatRepositoryProvider.overrideWithValue(chats),
        realtimeClientProvider.overrideWithValue(FakeRealtimeClient()),
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

  void whenOfferMade() {
    when(() => negotiations.makeOffer('l1',
            amount: any(named: 'amount'),
            clientRequestId: any(named: 'clientRequestId'),
            confirmLowOffer: any(named: 'confirmLowOffer')))
        .thenAnswer((_) async => MadeOffer(negotiation: negotiation(id: 'n9'), created: true));
  }

  testWidgets('tapping Make an Offer opens the sheet and then the new negotiation', (tester) async {
    whenOfferMade();
    await open(tester, _listing());

    await tester.tap(find.text('Make an Offer'));
    await tester.pumpAndSettle();
    expect(find.text('Make an offer'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '13000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();

    expect(find.text('negotiation n9'), findsOneWidget);
    verify(() => negotiations.makeOffer('l1',
        amount: '13000',
        clientRequestId: any(named: 'clientRequestId'),
        confirmLowOffer: false)).called(1);
  });

  testWidgets('the page is read again when the buyer comes back from the negotiation',
      (tester) async {
    whenOfferMade();
    await open(tester, _listing());

    await tester.tap(find.text('Make an Offer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '13000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    verify(() => listings.view('l1')).called(2);
  });

  testWidgets('a buyer who already has a negotiation sees View offer and goes straight to it',
      (tester) async {
    await open(tester, _listing(negotiationId: 'n5'));
    expect(find.text('View offer'), findsOneWidget);
    expect(find.text('Make an Offer'), findsNothing);

    await tester.tap(find.text('View offer'));
    await tester.pumpAndSettle();

    expect(find.text('negotiation n5'), findsOneWidget);
    verifyNever(() => negotiations.makeOffer(any(),
        amount: any(named: 'amount'), clientRequestId: any(named: 'clientRequestId')));
  });

  testWidgets('closing the sheet without an offer stays on the listing', (tester) async {
    await open(tester, _listing());

    await tester.tap(find.text('Make an Offer'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Make an Offer'), findsOneWidget);
    expect(find.textContaining('negotiation '), findsNothing);
  });

  testWidgets('a listing with no price opens nothing', (tester) async {
    await open(tester, _listing(price: null));

    await tester.tap(find.text('Make an Offer'));
    await tester.pumpAndSettle();

    expect(find.text('Make an offer'), findsNothing);
  });

  testWidgets('the sheet can open the chat with the seller first', (tester) async {
    when(() => chats.open('l1'))
        .thenAnswer((_) async => OpenedChat(thread: thread(id: 'new'), created: true));
    await open(tester, _listing());

    await tester.tap(find.text('Make an Offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat with seller'));
    await tester.pumpAndSettle();

    expect(find.text('thread new'), findsOneWidget);
  });

  testWidgets('says why the offer is not possible and does nothing when tapped', (tester) async {
    await open(tester, _listing(offerAvailable: false, offerReason: 'RESERVED'));

    expect(find.bySemanticsLabel('Make an Offer, Reserved right now'), findsOneWidget);
    await tester.tap(find.text('Make an Offer'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Make an offer'), findsNothing);
  });

  testWidgets('shows the server refusal when the offer is blocked', (tester) async {
    when(() => negotiations.makeOffer('l1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'),
        confirmLowOffer: any(named: 'confirmLowOffer'))).thenThrow(const ApiError(
      type: ApiErrorType.business,
      message: 'x',
      code: 'ERROR_ITEM_UNAVAILABLE',
      statusCode: 409,
    ));
    await open(tester, _listing());

    await tester.tap(find.text('Make an Offer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '13000');
    await tester.tap(find.text('Send offer'));
    await tester.pumpAndSettle();

    expect(find.text('This item is no longer available'), findsOneWidget);
  });

  test('PublicListing reads the negotiation id and the reserved reason', () {
    final listing = _listing(negotiationId: 'n5', offerAvailable: false, offerReason: 'RESERVED');

    expect(listing.negotiationId, 'n5');
    expect(listing.capabilities.offer.reason, CapabilityReason.reserved);
    expect(_listing().negotiationId, isNull);
  });
}
