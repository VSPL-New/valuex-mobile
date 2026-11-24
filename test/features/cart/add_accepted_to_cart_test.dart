import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/cart/presentation/add_accepted_to_cart.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';
import 'cart_fixtures.dart';

ApiError _refusal(String code, {int status = 409}) => ApiError(
      type: ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: status,
    );

void main() {
  setUpAll(loadBrandFonts);

  late MockCartRepository cart;

  setUp(() => cart = MockCartRepository());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => addAcceptedToCart(context, ref, 'l1'),
                child: const Text('add'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.cart,
          builder: (context, state) => const Scaffold(body: Text('cart screen')),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [cartRepositoryProvider.overrideWithValue(cart)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('adds the listing on its accepted price, says so and View cart opens the cart',
      (tester) async {
    when(() => cart.add('l1')).thenAnswer((_) async => addedLine());
    await open(tester);

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();

    verify(() => cart.add('l1')).called(1);
    expect(find.text('Added to your cart'), findsOneWidget);
    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('cart screen'), findsOneWidget);
  });

  testWidgets('a price that is no longer accepted says so', (tester) async {
    when(() => cart.add('l1')).thenThrow(_refusal('ERROR_PRICE_NOT_ACCEPTED'));
    await open(tester);

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();

    expect(find.textContaining("hasn't been accepted yet"), findsOneWidget);
    expect(find.text('View cart'), findsNothing);
  });

  testWidgets('a full cart says so', (tester) async {
    when(() => cart.add('l1')).thenThrow(_refusal('ERROR_MAX_CART_ITEMS'));
    await open(tester);

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();

    expect(find.text('Cart limit reached. Remove an item to add another'), findsOneWidget);
  });

  testWidgets('a cart that is not switched on yet says so and the listing is not touched',
      (tester) async {
    when(() => cart.add('l1')).thenThrow(_refusal('ERROR_CHECKOUT_UNAVAILABLE', status: 503));
    await open(tester);

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Added to your cart'), findsNothing);
  });

  testWidgets('a second tap while an add is running sends one request', (tester) async {
    when(() => cart.add('l1')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return addedLine();
    });
    await open(tester);

    await tester.tap(find.text('add'));
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();

    verify(() => cart.add('l1')).called(1);
  });
}
