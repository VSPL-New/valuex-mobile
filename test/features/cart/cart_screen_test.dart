import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/widgets/square_back_button.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/cart/presentation/cart_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/realtime/realtime_fakes.dart';
import '../../helpers/fonts.dart';
import 'cart_fixtures.dart';

ApiError _refusal(String code, {Map<String, String> details = const {}}) => ApiError(
      type: ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: 409,
      details: details,
    );

void main() {
  setUpAll(loadBrandFonts);

  late MockCartRepository cart;

  setUp(() => cart = MockCartRepository());

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 844),
    bool canPop = false,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final router = GoRouter(
      initialLocation: canPop ? '/start' : RouteNames.cart,
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(RouteNames.cart),
              child: const Text('go to cart'),
            ),
          ),
        ),
        GoRoute(path: RouteNames.cart, builder: (context, state) => const CartScreen()),
        GoRoute(
          path: RouteNames.cartDeliveryPattern,
          builder: (context, state) =>
              Scaffold(body: Text('delivery screen ${state.pathParameters['itemId']}')),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const Scaffold(body: Text('home screen')),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cart),
        realtimeClientProvider.overrideWithValue(FakeRealtimeClient()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pump();
    await tester.pump();
    if (canPop) {
      await tester.tap(find.text('go to cart'));
    }
    await tester.pumpAndSettle();
  }

  void cartHolds(List<Map<String, dynamic>> groups, {int? valid}) =>
      when(() => cart.get()).thenAnswer((_) async => cartOf(groups, valid: valid));

  final mixed = [
    groupJson('s1', 'Asha K', [
      lineJson('i1', title: 'Hero phone', agreedPrice: '4500.50'),
      lineJson(
        'i2',
        title: 'Old sofa',
        agreedPrice: '1200',
        currentPrice: '1500',
        status: 'EXPIRED',
        problem: 'ERROR_PRICE_CHANGED',
      ),
    ]),
    groupJson('s2', null, [
      lineJson('i3', title: 'Desk', agreedPrice: '800', status: 'PENDING'),
      lineJson('i4', title: null, status: 'UNAVAILABLE', problem: 'ERROR_ITEM_UNAVAILABLE'),
    ]),
  ];

  group('a cart with items', () {
    testWidgets('groups the lines by seller and shows price, status, time and delivery',
        (tester) async {
      cartHolds(mixed);
      await open(tester, size: const Size(390, 1600));

      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('4 items'), findsOneWidget);
      expect(find.text('Asha K'), findsOneWidget);
      expect(find.text('Seller'), findsOneWidget);
      expect(find.text('Hero phone'), findsOneWidget);
      expect(find.textContaining('Agreed price'), findsNWidgets(4));
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.textContaining('Price held for 14m'), findsOneWidget);
      expect(find.textContaining('Leaves your cart in'), findsNWidgets(4));
      expect(find.text('Choose at checkout'), findsNWidgets(4));
      expect(find.textContaining('Now asking'), findsOneWidget);
      expect(find.text('Price changed. Please review'), findsOneWidget);
      expect(find.text('No longer available'), findsNWidgets(2));
    });

    testWidgets('the total counts only what can be bought now and checkout stays off',
        (tester) async {
      cartHolds(mixed);
      await open(tester);

      expect(find.text('Total'), findsOneWidget);
      expect(find.textContaining('4,500.50'), findsWidgets);
      expect(find.text('Proceed to checkout'), findsOneWidget);
      expect(find.text('Checkout is coming soon'), findsOneWidget);
      final button = find.ancestor(
        of: find.text('Proceed to checkout'),
        matching: find.byWidgetPredicate((w) => w is InkWell || w is ElevatedButton),
      );
      for (final widget in tester.widgetList<Widget>(button)) {
        if (widget is InkWell) expect(widget.onTap, isNull);
      }
    });

    testWidgets('an expired line says it left the cart and shows no countdown for the line',
        (tester) async {
      cartHolds([
        groupJson('s1', 'Asha K', [
          lineJson('i1', status: 'EXPIRED', problem: 'ERROR_CART_EXPIRED'),
          lineJson('i2', status: 'EXPIRED', problem: 'ERROR_ACCEPTANCE_EXPIRED'),
        ]),
      ]);
      await open(tester);

      expect(find.text('Cart item expired. Please add again'), findsOneWidget);
      expect(find.text('Price acceptance expired. Make a new offer'), findsOneWidget);
      expect(find.textContaining('Leaves your cart in'), findsOneWidget);
    });
  });

  group('an empty or failing cart', () {
    testWidgets('an empty cart explains how to fill it and shows no footer', (tester) async {
      cartHolds([]);
      await open(tester);

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.textContaining('Add an item once the seller accepts'), findsOneWidget);
      expect(find.text('Proceed to checkout'), findsNothing);
      expect(find.textContaining('items'), findsNothing);
    });

    testWidgets('waits with a spinner while the cart loads', (tester) async {
      final pending = Completer<void>();
      when(() => cart.get()).thenAnswer((_) async {
        await pending.future;
        return cartOf([]);
      });
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cart),
          realtimeClientProvider.overrideWithValue(FakeRealtimeClient()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CartScreen(),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a failed load shows an error and Retry reads the cart again', (tester) async {
      when(() => cart.get()).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'offline'),
      );
      await open(tester);
      expect(find.text('Retry'), findsOneWidget);

      cartHolds([]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('pull to refresh reads the cart again', (tester) async {
      cartHolds(mixed);
      await open(tester);
      cartHolds([]);

      await tester.fling(find.text('Hero phone'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('a refresh that fails keeps the lines and says so', (tester) async {
      cartHolds(mixed);
      await open(tester);
      when(() => cart.get()).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'offline'),
      );

      await tester.fling(find.text('Hero phone'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Hero phone'), findsOneWidget);
      expect(
        find.text("Couldn't refresh your cart. Showing what it held a moment ago"),
        findsOneWidget,
      );
    });
  });

  group('delivery on a line (US-020)', () {
    testWidgets('only a line that can be bought offers Choose delivery', (tester) async {
      cartHolds(mixed);
      await open(tester, size: const Size(390, 1600));

      expect(find.text('Choose delivery'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Choose at checkout'), findsNWidgets(4));
    });

    testWidgets('Choose delivery opens the delivery screen of that line', (tester) async {
      cartHolds([
        groupJson('s1', 'Asha K', [lineJson('i7')]),
      ]);
      await open(tester);

      await tester.tap(find.text('Choose delivery'));
      await tester.pumpAndSettle();

      expect(find.text('delivery screen i7'), findsOneWidget);
    });

    testWidgets('a chosen delivery shows its cost and date, and the button reads Change',
        (tester) async {
      cartHolds([
        groupJson('s1', 'Asha K', [
          lineJson(
            'i1',
            delivery: deliveryJson(
              mode: 'DELIVERY',
              addressId: 'a1',
              cost: '60.00',
              eta: '2026-11-25',
            ),
          ),
        ]),
      ]);
      await open(tester);

      expect(find.text('Delivery, ₹60, by Nov 25'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Choose delivery'), findsNothing);
      expect(find.text('Choose at checkout'), findsNothing);
    });

    testWidgets('a chosen self-pickup shows how the buyer pays', (tester) async {
      cartHolds([
        groupJson('s1', 'Asha K', [
          lineJson('i1', delivery: deliveryJson(mode: 'SELF_PICKUP', payment: 'PAY_NOW')),
          lineJson(
            'i2',
            title: 'Desk',
            delivery: deliveryJson(mode: 'SELF_PICKUP', payment: 'PAY_AT_PICKUP'),
          ),
        ]),
      ]);
      await open(tester, size: const Size(390, 1600));

      expect(find.text('Self-pickup, pay now'), findsOneWidget);
      expect(find.text('Self-pickup, pay at pickup'), findsOneWidget);
    });

    testWidgets('the choice is read out with the line', (tester) async {
      final handle = tester.ensureSemantics();
      cartHolds([
        groupJson('s1', 'Asha K', [
          lineJson(
            'i1',
            delivery: deliveryJson(
              mode: 'DELIVERY',
              addressId: 'a1',
              cost: 60,
              eta: '2026-11-25',
            ),
          ),
        ]),
      ]);
      await open(tester);

      expect(
        find.bySemanticsLabel(RegExp(r'^Hero phone, .*from Asha K.*Delivery, ₹60, by Nov 25')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('Remove and Undo', () {
    final single = [
      groupJson('s1', 'Asha K', [lineJson('i1', listingId: 'l1')]),
      groupJson('s2', 'Ravi', [lineJson('i2', listingId: 'l2', title: 'Desk')]),
    ];

    testWidgets('Remove takes the line out, offers Undo, and Undo adds it back', (tester) async {
      cartHolds(single);
      when(() => cart.remove('i1')).thenAnswer((_) async {
        cartHolds([single.last]);
      });
      when(() => cart.add('l1')).thenAnswer((_) async {
        cartHolds(single);
        return addedLine();
      });
      await open(tester);

      await tester.tap(find.text('Remove').first);
      await tester.pumpAndSettle();

      expect(find.text('Hero phone'), findsNothing);
      expect(find.text('Removed from your cart'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      verify(() => cart.add('l1')).called(1);
      expect(find.text('Hero phone'), findsOneWidget);
    });

    testWidgets('an Undo the server refuses says why', (tester) async {
      cartHolds(single);
      when(() => cart.remove('i1')).thenAnswer((_) async => cartHolds([single.last]));
      when(() => cart.add('l1')).thenThrow(_refusal('ERROR_PRICE_NOT_ACCEPTED'));
      await open(tester);

      await tester.tap(find.text('Remove').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Hero phone'), findsNothing);
      expect(find.textContaining("hasn't been accepted yet"), findsOneWidget);
    });

    testWidgets('a removal that fails keeps the line and says why', (tester) async {
      cartHolds(single);
      when(() => cart.remove('i1')).thenThrow(_refusal('ERROR_CART_ITEM_NOT_FOUND'));
      await open(tester);

      await tester.tap(find.text('Remove').first);
      await tester.pumpAndSettle();

      expect(find.text('Hero phone'), findsOneWidget);
      expect(find.text('This item is not in your cart'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });
  });

  group('navigation, accessibility and language', () {
    testWidgets('back returns to the previous screen, or Home when there is none', (tester) async {
      cartHolds([]);
      await open(tester, canPop: true);
      await tester.tap(find.byType(SquareBackButton));
      await tester.pumpAndSettle();
      expect(find.text('go to cart'), findsOneWidget);
    });

    testWidgets('back goes Home when the cart was opened directly', (tester) async {
      cartHolds([]);
      await open(tester);

      await tester.tap(find.byType(SquareBackButton));
      await tester.pumpAndSettle();

      expect(find.text('home screen'), findsOneWidget);
    });

    testWidgets('the title and seller names are headers and each card is one spoken sentence',
        (tester) async {
      final handle = tester.ensureSemantics();
      cartHolds(mixed);
      await open(tester);

      expect(tester.getSemantics(find.text('Cart')), isSemantics(isHeader: true));
      expect(find.bySemanticsLabel(RegExp('^Hero phone, .*Accepted, from Asha K')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Old sofa, .*Expired, from Asha K. Price changed')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'^Total, .*4,500\.50')), findsOneWidget);
      handle.dispose();
    });

    for (final locale in ['en', 'hi']) {
      testWidgets('does not overflow at 320 px and 200 percent text in $locale', (tester) async {
        cartHolds(mixed);
        await open(tester, locale: Locale(locale), textScale: 2, size: const Size(320, 640));

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows Hindi text when the language is Hindi', (tester) async {
      cartHolds(mixed);
      await open(tester, locale: const Locale('hi'));

      expect(find.text('Cart'), findsNothing);
      expect(find.text('Proceed to checkout'), findsNothing);
    });

    testWidgets('passes the tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      cartHolds(mixed);
      await open(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
