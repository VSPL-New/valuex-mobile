import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/negotiation/data/negotiation_repository.dart';
import 'package:valuex_mobile/features/negotiation/domain/negotiation.dart';
import 'package:valuex_mobile/features/negotiation/presentation/providers/negotiation_controller.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/realtime/realtime_fakes.dart';

class MockNegotiationRepository extends Mock implements NegotiationRepository {}

/// The server's time in every fixture, so countdowns are exact.
final DateTime serverNow = DateTime.utc(2026, 11, 17, 10);

Map<String, dynamic> offerJson(
  String id,
  String party,
  num amount,
  int round, {
  String status = 'PENDING',
}) =>
    {
      'offerId': id,
      'party': party,
      'amount': amount,
      'round': round,
      'status': status,
      'createdAt': '2026-11-17T09:00:00Z',
    };

/// A buyer-side negotiation waiting for the seller, unless changed.
Map<String, dynamic> negotiationJson({
  String id = 'n1',
  String role = 'BUYER',
  String state = 'SELLER_REVIEWING',
  String awaiting = 'SELLER',
  List<Map<String, dynamic>>? offers,
  int round = 1,
  int maxRounds = 5,
  num? agreedPrice,
  String? priceLockExpiresAt,
  String? expiresAt = '2026-11-17T14:20:00Z',
  Map<String, dynamic>? actions,
  Map<String, dynamic>? counterRange,
  bool available = true,
  bool realEstate = false,
  String? threadId = 't1',
}) =>
    {
      'negotiationId': id,
      'role': role,
      'state': state,
      'awaiting': awaiting,
      'listing': {
        'listingId': 'l1',
        'title': 'Apple Watch',
        'thumbnailUrl': null,
        'askingPrice': 14500,
        'available': available,
        'realEstate': realEstate,
      },
      'buyer': {'userId': 'u-buyer', 'displayName': 'Ravi', 'rating': null},
      'seller': {'userId': 'u-seller', 'displayName': 'Asha K', 'rating': null},
      'round': round,
      'maxRounds': maxRounds,
      'offers': offers ?? [offerJson('o1', 'BUYER', 12000, 1)],
      'agreedPrice': agreedPrice,
      'priceLockExpiresAt': priceLockExpiresAt,
      'expiresAt': expiresAt,
      'warnAt': null,
      'actions': actions ??
          {'canAccept': false, 'canReject': false, 'canCounter': false, 'canCancel': true},
      'counterRange': counterRange,
      'threadId': threadId,
      'serverTime': '2026-11-17T10:00:00Z',
    };

Negotiation negotiation({
  String id = 'n1',
  String role = 'BUYER',
  String state = 'SELLER_REVIEWING',
  String awaiting = 'SELLER',
  List<Map<String, dynamic>>? offers,
  int round = 1,
  num? agreedPrice,
  String? priceLockExpiresAt,
  String? expiresAt = '2026-11-17T14:20:00Z',
  Map<String, dynamic>? actions,
  Map<String, dynamic>? counterRange,
  bool available = true,
  bool realEstate = false,
  String? threadId = 't1',
}) =>
    Negotiation.fromJson(negotiationJson(
      id: id,
      role: role,
      state: state,
      awaiting: awaiting,
      offers: offers,
      round: round,
      agreedPrice: agreedPrice,
      priceLockExpiresAt: priceLockExpiresAt,
      expiresAt: expiresAt,
      actions: actions,
      counterRange: counterRange,
      available: available,
      realEstate: realEstate,
      threadId: threadId,
    ));

/// The seller's view of a buyer offer of 12,000 waiting for them, with all three answers allowed.
Negotiation sellerTurn() => negotiation(
      role: 'SELLER',
      actions: {'canAccept': true, 'canReject': true, 'canCounter': true, 'canCancel': false},
      counterRange: {'min': 12000.01, 'max': 14500},
    );

/// The buyer's view of a seller counter of 13,500 waiting for them.
Negotiation buyerTurn() => negotiation(
      state: 'BUYER_REVIEWING',
      awaiting: 'BUYER',
      round: 2,
      offers: [
        offerJson('o1', 'BUYER', 12000, 1, status: 'SUPERSEDED'),
        offerJson('o2', 'SELLER', 13500, 2),
      ],
      actions: {'canAccept': true, 'canReject': true, 'canCounter': true, 'canCancel': true},
      counterRange: {'min': 12000, 'max': 13499.99},
    );

/// Pumps [home] at "/" inside a small router whose other routes only name where they lead.
Future<FakeRealtimeClient> pumpNegotiationApp(
  WidgetTester tester,
  Widget home, {
  required MockNegotiationRepository repo,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(390, 844),
  FakeRealtimeClient? realtime,
  Duration? pollInterval,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final fake = realtime ?? FakeRealtimeClient();
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: '/chats/:threadId',
        builder: (context, state) =>
            Scaffold(body: Text('thread ${state.pathParameters['threadId']}')),
      ),
      GoRoute(
        path: '/listing/:listingId',
        builder: (context, state) =>
            Scaffold(body: Text('listing ${state.pathParameters['listingId']}')),
      ),
      GoRoute(
        path: '/negotiations/:negotiationId',
        builder: (context, state) =>
            Scaffold(body: Text('negotiation ${state.pathParameters['negotiationId']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        negotiationRepositoryProvider.overrideWithValue(repo),
        negotiationPollIntervalProvider.overrideWithValue(pollInterval),
        realtimeClientProvider.overrideWithValue(fake),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return fake;
}
