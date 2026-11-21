import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/features/address/data/address_repository.dart';
import 'package:valuex_mobile/features/address/domain/address_value.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';
import 'package:valuex_mobile/features/address/presentation/providers/address_providers.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/cart/domain/cart.dart';
import 'package:valuex_mobile/features/cart/domain/delivery.dart';
import 'package:valuex_mobile/features/cart/presentation/delivery_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/realtime/realtime_fakes.dart';
import '../../helpers/fonts.dart';
import 'cart_fixtures.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

ApiError _refusal(String code, {Map<String, String> details = const {}, int status = 409}) =>
    ApiError(
      type: ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: status,
      details: details,
    );

void main() {
  setUpAll(() async {
    await loadBrandFonts();
    registerFallbackValue(DeliveryMode.delivery);
    registerFallbackValue(PaymentOption.payNow);
    registerFallbackValue(
        const AddressValue(address: 'a', city: 'c', state: 's', pincode: '560001'));
  });

  late MockCartRepository cart;
  late MockAddressRepository addressRepository;
  late List<SavedAddress> addresses;
  late Map<String, dynamic> line;

  setUp(() {
    cart = MockCartRepository();
    addressRepository = MockAddressRepository();
    addresses = [homeAddress, officeAddress];
    line = lineJson('i1');
    when(() => cart.get()).thenAnswer((_) async => cartOf([
          groupJson('s1', 'Asha K', [line]),
        ]));
    when(() => cart.deliveryOptions('i1')).thenAnswer((_) async => optionsOf());
    when(() => cart.deliveryOptions('i1', addressId: 'a1')).thenAnswer(
      (_) async => optionsOf(cost: '60.00', eta: '2026-11-25'),
    );
    when(() => cart.deliveryOptions('i1', addressId: 'a2')).thenAnswer(
      (_) async => optionsOf(cost: '60.00', eta: '2026-11-26'),
    );
    when(() => cart.chooseDelivery(
          any(),
          mode: any(named: 'mode'),
          addressId: any(named: 'addressId'),
          paymentOption: any(named: 'paymentOption'),
          expectedShippingCost: any(named: 'expectedShippingCost'),
          termsAccepted: any(named: 'termsAccepted'),
        )).thenAnswer((_) async => CartLine.fromJson(line));
    when(() => addressRepository.verify(any())).thenAnswer((_) async {});
  });

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 1400),
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final router = GoRouter(
      initialLocation: RouteNames.cartDelivery('i1'),
      routes: [
        GoRoute(
          path: RouteNames.cartDeliveryPattern,
          builder: (context, state) => DeliveryScreen(itemId: state.pathParameters['itemId']!),
        ),
        GoRoute(
          path: RouteNames.cart,
          builder: (context, state) => const Scaffold(body: Text('cart screen')),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_config),
        cartRepositoryProvider.overrideWithValue(cart),
        addressRepositoryProvider.overrideWithValue(addressRepository),
        addressSearchServiceProvider.overrideWithValue(FakeAddressSearch()),
        savedAddressesProvider.overrideWith((ref) async => List.of(addresses)),
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
    await tester.pumpAndSettle();
  }

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<BrandGradientButton>(find.byType(BrandGradientButton)).onPressed != null;

  Future<void> tickTerms(WidgetTester tester) async {
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(BrandGradientButton));
    await tester.tap(find.byType(BrandGradientButton));
    await tester.pumpAndSettle();
  }

  group('delivery', () {
    testWidgets('shows both ways and the item, and opens delivery with the default address priced',
        (tester) async {
      await open(tester);

      expect(find.text('Delivery or pickup'), findsOneWidget);
      expect(find.text('Hero phone'), findsOneWidget);
      expect(find.text('How do you want to receive this?'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Self-pickup'), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      expect(find.text('Delivery address'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Default'), findsWidgets);
      expect(find.text('Shipping ₹60'), findsOneWidget);
      expect(find.text('Arrives by Nov 25'), findsOneWidget);
      verify(() => cart.deliveryOptions('i1', addressId: 'a1')).called(1);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('prices another address when it is picked', (tester) async {
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('9 Baner Road'));
      await tester.pumpAndSettle();

      expect(find.text('Arrives by Nov 26'), findsOneWidget);
      verify(() => cart.deliveryOptions('i1', addressId: 'a2')).called(1);
    });

    testWidgets('saves delivery to the address, with the cost shown and the terms agreed',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      expect(find.textContaining('delivered to the address I chose'), findsOneWidget);

      await tickTerms(tester);
      expect(saveEnabled(tester), isTrue);
      await save(tester);

      verify(() => cart.chooseDelivery(
            'i1',
            mode: DeliveryMode.delivery,
            addressId: 'a1',
            paymentOption: null,
            expectedShippingCost: 60,
            termsAccepted: true,
          )).called(1);
      verify(() => cart.get()).called(2);
      expect(find.text('cart screen'), findsOneWidget);
    });

    testWidgets('needs the terms before Save works, and asks again after a change', (tester) async {
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      await tickTerms(tester);
      expect(saveEnabled(tester), isTrue);

      await tester.tap(find.textContaining('9 Baner Road'));
      await tester.pumpAndSettle();

      expect(saveEnabled(tester), isFalse);
      expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
    });

    testWidgets('warns when shipping costs more than the item', (tester) async {
      when(() => cart.deliveryOptions('i1', addressId: 'a1')).thenAnswer((_) async => optionsOf(
            cost: '1000.00',
            eta: '2026-11-25',
            warning: 'SHIPPING_EXCEEDS_PRICE',
          ));
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      expect(find.text('Shipping ₹1,000'), findsOneWidget);
      expect(find.text('Shipping costs more than this item'), findsOneWidget);
    });

    testWidgets('says to add an address when there is none', (tester) async {
      addresses = [];
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      expect(find.text('Add an address to see the shipping cost and date'), findsOneWidget);
      expect(find.text('Add a new address'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      verifyNever(() => cart.deliveryOptions('i1', addressId: 'a1'));
      verifyNever(() => cart.deliveryOptions('i1', addressId: 'a2'));
    });

    testWidgets('a pricing failure can be retried', (tester) async {
      var calls = 0;
      when(() => cart.deliveryOptions('i1', addressId: 'a1')).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw const ApiError(type: ApiErrorType.network, message: 'offline');
        return optionsOf(cost: '60.00', eta: '2026-11-25');
      });
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      expect(find.text("We couldn't work out the shipping cost. Please try again"), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Shipping ₹60'), findsOneWidget);
    });

    testWidgets('an address the server calls incomplete says so', (tester) async {
      when(() => cart.deliveryOptions('i1', addressId: 'a1'))
          .thenAnswer((_) async => throw _refusal('ERROR_INVALID_ADDRESS', status: 422));
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter complete delivery address'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('a changed shipping cost is refused, shown, and must be agreed again',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      await tickTerms(tester);
      when(() => cart.chooseDelivery(
                any(),
                mode: any(named: 'mode'),
                addressId: any(named: 'addressId'),
                paymentOption: any(named: 'paymentOption'),
                expectedShippingCost: any(named: 'expectedShippingCost'),
                termsAccepted: any(named: 'termsAccepted'),
              ))
          .thenAnswer((_) async =>
              throw _refusal('ERROR_SHIPPING_CHANGED', details: {'shippingCost': '90.00'}));
      when(() => cart.deliveryOptions('i1', addressId: 'a1')).thenAnswer(
        (_) async => optionsOf(cost: '90.00', eta: '2026-11-25'),
      );

      await save(tester);

      expect(find.text('Shipping cost has changed to ₹90. Please review'), findsOneWidget);
      expect(find.text('Shipping ₹90'), findsOneWidget);
      expect(find.text('cart screen'), findsNothing);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('delivery that is not possible stays dimmed and says why', (tester) async {
      when(() => cart.deliveryOptions('i1')).thenAnswer((_) async => optionsOf(delivery: false));
      await open(tester);

      expect(find.text("Seller doesn't offer delivery to your location"), findsOneWidget);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      expect(find.text('Delivery address'), findsNothing);
      expect(find.text('Pickup location'), findsOneWidget);
    });
  });

  group('self-pickup', () {
    testWidgets('shows the pickup place and the seller, and two ways to pay', (tester) async {
      await open(tester);
      await tester.tap(find.text('Self-pickup'));
      await tester.pumpAndSettle();

      expect(find.text('Pickup location'), findsOneWidget);
      expect(find.text('4 FC Road, Pune, Maharashtra 411004'), findsOneWidget);
      expect(find.text('Seller: Asha K'), findsOneWidget);
      expect(
        find.text("The full address and the seller's contact are shown after you place the order."),
        findsOneWidget,
      );
      expect(find.text('Pay Now'), findsOneWidget);
      expect(find.text('Pay at Pickup'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('saves Pay Now with the escrow terms and no address', (tester) async {
      await open(tester);
      await tester.tap(find.text('Self-pickup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay Now'));
      await tester.pumpAndSettle();
      expect(find.textContaining('stays in escrow and is released to the seller'), findsOneWidget);
      expect(find.text('Pay at Pickup is not protected by escrow'), findsNothing);

      await tickTerms(tester);
      await save(tester);

      verify(() => cart.chooseDelivery(
            'i1',
            mode: DeliveryMode.selfPickup,
            addressId: null,
            paymentOption: PaymentOption.payNow,
            expectedShippingCost: null,
            termsAccepted: true,
          )).called(1);
      expect(find.text('cart screen'), findsOneWidget);
    });

    testWidgets('Pay at Pickup warns that it is not protected by escrow', (tester) async {
      await open(tester);
      await tester.tap(find.text('Self-pickup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay at Pickup'));
      await tester.pumpAndSettle();

      expect(find.text('Pay at Pickup is not protected by escrow'), findsOneWidget);
      expect(find.textContaining('not protected by escrow, and JustQlic cannot refund'),
          findsOneWidget);

      await tickTerms(tester);
      await save(tester);

      verify(() => cart.chooseDelivery(
            'i1',
            mode: DeliveryMode.selfPickup,
            addressId: null,
            paymentOption: PaymentOption.payAtPickup,
            expectedShippingCost: null,
            termsAccepted: true,
          )).called(1);
    });

    testWidgets('self-pickup that is not possible says why and delivery opens by itself',
        (tester) async {
      when(() => cart.deliveryOptions('i1')).thenAnswer((_) async => optionsOf(pickup: false));
      await open(tester);

      expect(find.text('Self-pickup not available for this item'), findsOneWidget);
      expect(find.text('Delivery address'), findsOneWidget);
      expect(find.text('Shipping ₹60'), findsOneWidget);
    });

    testWidgets('a refusal from the server is shown and the screen stays', (tester) async {
      when(() => cart.chooseDelivery(
            any(),
            mode: any(named: 'mode'),
            addressId: any(named: 'addressId'),
            paymentOption: any(named: 'paymentOption'),
            expectedShippingCost: any(named: 'expectedShippingCost'),
            termsAccepted: any(named: 'termsAccepted'),
          )).thenAnswer((_) async => throw _refusal('ERROR_NO_SELF_PICKUP'));
      await open(tester);
      await tester.tap(find.text('Self-pickup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay Now'));
      await tester.pumpAndSettle();
      await tickTerms(tester);

      await save(tester);

      expect(find.text('Self-pickup not available for this item'), findsWidgets);
      expect(find.text('cart screen'), findsNothing);
    });
  });

  group('what the buyer chose before', () {
    testWidgets('opens on the earlier self-pickup choice', (tester) async {
      line = lineJson('i1', delivery: deliveryJson(mode: 'SELF_PICKUP', payment: 'PAY_AT_PICKUP'));
      await open(tester);

      expect(find.text('Pickup location'), findsOneWidget);
      expect(find.text('Pay at Pickup is not protected by escrow'), findsOneWidget);
    });

    testWidgets('opens on the earlier delivery address', (tester) async {
      line = lineJson(
        'i1',
        delivery: deliveryJson(mode: 'DELIVERY', addressId: 'a2', cost: 60, eta: '2026-11-26'),
      );
      await open(tester);

      verify(() => cart.deliveryOptions('i1', addressId: 'a2')).called(1);
      verifyNever(() => cart.deliveryOptions('i1', addressId: 'a1'));
      expect(find.text('Arrives by Nov 26'), findsOneWidget);
    });
  });

  group('errors and states', () {
    testWidgets('waits with a spinner while the options load', (tester) async {
      when(() => cart.deliveryOptions('i1')).thenAnswer((_) => Completer<DeliveryOptions>().future);
      tester.view.physicalSize = const Size(780, 2800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cart),
          savedAddressesProvider.overrideWith((ref) async => addresses),
          realtimeClientProvider.overrideWithValue(FakeRealtimeClient()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeliveryScreen(itemId: 'i1'),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a failed load shows the reason with Retry', (tester) async {
      var calls = 0;
      when(() => cart.deliveryOptions('i1')).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw _refusal('ERROR_ACCEPTANCE_EXPIRED');
        return optionsOf();
      });
      await open(tester);

      expect(find.text('Price acceptance expired. Make a new offer'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('How do you want to receive this?'), findsOneWidget);
    });

    testWidgets('a failed address list shows an error with Retry', (tester) async {
      var calls = 0;
      tester.view.physicalSize = const Size(780, 2800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cart),
          savedAddressesProvider.overrideWith((ref) async {
            calls++;
            if (calls == 1) throw const ApiError(type: ApiErrorType.network, message: 'offline');
            return addresses;
          }),
          realtimeClientProvider.overrideWithValue(FakeRealtimeClient()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeliveryScreen(itemId: 'i1'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text("We couldn't load the delivery options"), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('How do you want to receive this?'), findsOneWidget);
    });

    testWidgets('a line that is not in the cart says so', (tester) async {
      when(() => cart.get()).thenAnswer((_) async => cartOf([]));
      await open(tester);

      expect(find.text('This item is not in your cart'), findsOneWidget);
    });

    testWidgets('back returns to the cart', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Back').evaluate().isEmpty
          ? find.bySemanticsLabel('Back')
          : find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('cart screen'), findsOneWidget);
    });
  });

  group('adding an address', () {
    testWidgets('a new address is saved, picked and priced', (tester) async {
      when(() => addressRepository.create(any(),
          label: any(named: 'label'),
          makeDefault: any(named: 'makeDefault'))).thenAnswer((_) async {
        const saved = SavedAddress(
          id: 'a3',
          label: 'Home',
          address: '4 Residency Road, Shanti Nagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560025',
        );
        addresses = [...addresses, saved];
        return saved;
      });
      when(() => cart.deliveryOptions('i1', addressId: 'a3')).thenAnswer(
        (_) async => optionsOf(cost: '60.00', eta: '2026-11-27'),
      );
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add a new address'));
      await tester.pumpAndSettle();
      expect(find.text('New address'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Resid');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 Residency Road'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      verify(() => addressRepository.create(
            const AddressValue(
              address: '4 Residency Road, Shanti Nagar',
              city: 'Bengaluru',
              state: 'Karnataka',
              pincode: '560025',
              placeId: 'p1',
            ),
            label: 'Home',
            makeDefault: false,
          )).called(1);
      expect(find.text('New address'), findsNothing);
      expect(find.text('Arrives by Nov 27'), findsOneWidget);
      verify(() => cart.deliveryOptions('i1', addressId: 'a3')).called(1);
    });
  });

  group('language, layout and accessibility', () {
    for (final locale in ['en', 'hi']) {
      testWidgets('does not overflow at 320 px and 200 percent text in $locale', (tester) async {
        await open(tester, locale: Locale(locale), textScale: 2, size: const Size(320, 1600));
        await tester.tap(find.byType(InkWell).at(1));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows Hindi text when the language is Hindi', (tester) async {
      await open(tester, locale: const Locale('hi'));

      expect(find.text('Delivery or pickup'), findsNothing);
      expect(find.text('डिलीवरी या पिकअप'), findsOneWidget);
    });

    testWidgets('options are one radio-like button each and meet the tap target guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Delivery'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('^Home, Flat 4, 12 MG Road')), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
