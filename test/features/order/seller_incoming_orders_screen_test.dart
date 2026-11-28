import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/order/data/mock_seller_order_repository.dart';
import 'package:valuex_mobile/features/order/domain/entities/incoming_order.dart';
import 'package:valuex_mobile/features/order/domain/repositories/seller_order_repository.dart';
import 'package:valuex_mobile/features/order/presentation/providers/seller_order_providers.dart';
import 'package:valuex_mobile/features/order/presentation/seller_incoming_orders_screen.dart';
import 'package:valuex_mobile/features/order/presentation/widgets/buyer_initials_avatar.dart';
import 'package:valuex_mobile/features/order/presentation/widgets/incoming_order_card.dart';
import 'package:valuex_mobile/features/order/presentation/widgets/order_count_tile.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements SellerOrderRepository {}

IncomingOrder _order(
  String id, {
  FulfilmentBucket bucket = FulfilmentBucket.newOrder,
  List<OrderTag> tags = const [],
  List<SellerOrderAction> actions = const [],
  String? buyerName = 'Ananya Sharma',
  String? bookingError,
  PickupAddress? pickupAddress,
  String title = 'Vintage Leica M6 Film Camera',
}) =>
    IncomingOrder(
      id: id,
      orderNumber: 'VX-$id',
      bucket: bucket,
      orderState: 'SHIPPING_MODE_SELECTED',
      tags: tags,
      placedAt: DateTime.now().subtract(const Duration(hours: 2)),
      amount: 185000,
      title: title,
      buyerName: buyerName,
      actions: actions,
      bookingError: bookingError,
      pickupAddress: pickupAddress,
    );

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

void main() {
  setUpAll(loadBrandFonts);

  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.summary())
        .thenAnswer((_) async => const OrdersSummary(total: 1, newOrders: 1));
  });

  void serve(List<IncomingOrder> items, {bool hasMore = false}) {
    when(() => repository.orders(page: any(named: 'page')))
        .thenAnswer((_) async => IncomingOrdersPage(items: items, page: 0, hasMore: hasMore));
  }

  Future<void> pump(
    WidgetTester tester, {
    SellerOrderRepository? repo,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: RouteNames.sellerOrders,
      routes: [
        GoRoute(
          path: RouteNames.profile,
          builder: (context, state) => const Scaffold(body: Text('profile page')),
        ),
        GoRoute(
          path: RouteNames.sellerOrders,
          builder: (context, state) => const SellerIncomingOrdersScreen(),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [sellerOrderRepositoryProvider.overrideWithValue(repo ?? repository)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the Make sample page: header, counts, cards and footer', (tester) async {
    await pump(tester, repo: MockSellerOrderRepository());

    expect(find.text('Incoming Orders'), findsOneWidget);
    expect(find.text('4 orders · 1 new'), findsOneWidget);
    expect(find.text('1 New'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Incoming Orders')), findsWidgets);
    expect(find.byType(OrderCountTile), findsNWidgets(4));
    expect(find.text('#ORD-S-1001'), findsOneWidget);
    expect(find.text('URGENT'), findsOneWidget);
    expect(find.text('New Order'), findsOneWidget);
    expect(find.text('₹42,000'), findsOneWidget);
    expect(find.text('Buyer: Ananya Sharma'), findsOneWidget);
    expect(find.text('Start Packing'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Showing all 4 incoming orders'), 300);
    expect(find.text('Order Shipped'), findsOneWidget);
    expect(find.text('View Schedule'), findsOneWidget);
    expect(find.text('Reschedule Pickup'), findsOneWidget);
  });

  testWidgets('shows the empty state with zero counts and no badge', (tester) async {
    when(() => repository.summary()).thenAnswer((_) async => const OrdersSummary());
    serve(const []);
    await pump(tester);

    expect(find.text('0 orders · 0 new'), findsOneWidget);
    expect(find.text('0 New'), findsNothing);
    expect(
      find.text('No incoming orders yet. Orders for your listings will appear here'),
      findsOneWidget,
    );
    expect(find.textContaining('Showing all'), findsNothing);
  });

  testWidgets('shows an error with Retry when nothing could be loaded', (tester) async {
    when(() => repository.summary()).thenThrow(_offline);
    serve(const []);
    await pump(tester);

    expect(
        find.text('Unable to load your incoming orders. Pull down or tap Retry'), findsOneWidget);
    when(() => repository.summary())
        .thenAnswer((_) async => const OrdersSummary(total: 1, newOrders: 1));
    serve([
      _order('a', actions: const [SellerOrderAction.startPacking])
    ]);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('#VX-a'), findsOneWidget);
  });

  testWidgets('keeps the last loaded list with a message when a refresh fails', (tester) async {
    serve([_order('a')]);
    await pump(tester);
    when(() => repository.summary()).thenThrow(_offline);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('#VX-a'), findsOneWidget);
    expect(
        find.text('Unable to load your incoming orders. Pull down or tap Retry'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Start Packing calls the server, reloads and says packing is coming', (tester) async {
    serve([
      _order('a', actions: const [SellerOrderAction.startPacking, SellerOrderAction.reject])
    ]);
    when(() => repository.startPacking('a')).thenAnswer((_) async => _order('a'));
    await pump(tester);

    await tester.tap(find.text('Start Packing'));
    await tester.pumpAndSettle();

    verify(() => repository.startPacking('a')).called(1);
    verify(() => repository.summary()).called(2);
    expect(find.text('This is coming soon'), findsOneWidget);
  });

  testWidgets('a refused action says the order moved on and reloads', (tester) async {
    serve([
      _order('a', actions: const [SellerOrderAction.startPacking])
    ]);
    when(() => repository.startPacking('a')).thenThrow(const ApiError(
        type: ApiErrorType.business, message: 'x', code: 'ERROR_ORDER_ACTION_NOT_ALLOWED'));
    await pump(tester);

    await tester.tap(find.text('Start Packing'));
    await tester.pumpAndSettle();

    expect(find.text('This order has already moved to the next step. Refreshing'), findsOneWidget);
    verify(() => repository.summary()).called(2);
  });

  testWidgets('an order that is gone, or a network failure, is told plainly', (tester) async {
    serve([
      _order('a', actions: const [SellerOrderAction.startPacking])
    ]);
    when(() => repository.startPacking('a')).thenThrow(
        const ApiError(type: ApiErrorType.business, message: 'x', code: 'ERROR_ORDER_NOT_FOUND'));
    await pump(tester);

    await tester.tap(find.text('Start Packing'));
    await tester.pumpAndSettle();
    expect(find.text('This order is no longer available'), findsOneWidget);

    when(() => repository.startPacking('a')).thenThrow(_offline);
    await tester.tap(find.text('Start Packing'));
    await tester.pumpAndSettle();
    expect(find.text('This order is no longer available'), findsNothing);
  });

  testWidgets('Mark as handed over asks first and does nothing when cancelled', (tester) async {
    serve([
      _order('a', tags: const [
        OrderTag.selfPickup
      ], actions: const [
        SellerOrderAction.viewPickupDetails,
        SellerOrderAction.markHandedOver,
        SellerOrderAction.reject,
      ]),
    ]);
    when(() => repository.markHandedOver('a')).thenAnswer((_) async => _order('a'));
    await pump(tester);
    expect(find.text('Self Pickup by Buyer'), findsOneWidget);

    await tester.tap(find.text('Mark as handed over'));
    await tester.pumpAndSettle();
    expect(find.text('Has the buyer collected the item?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => repository.markHandedOver(any()));

    await tester.tap(find.text('Mark as handed over'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, handed over'));
    await tester.pumpAndSettle();
    verify(() => repository.markHandedOver('a')).called(1);
  });

  testWidgets('View Pickup Details shows the address the buyer sees', (tester) async {
    serve([
      _order('a',
          tags: const [OrderTag.selfPickup],
          actions: const [SellerOrderAction.viewPickupDetails],
          pickupAddress: const PickupAddress(
              line1: '4 Park Street', city: 'Kolkata', state: 'West Bengal', pincode: '700016')),
    ]);
    await pump(tester);

    await tester.tap(find.text('View Pickup Details'));
    await tester.pumpAndSettle();

    expect(find.text('Pickup details'), findsOneWidget);
    expect(find.text('4 Park Street'), findsOneWidget);
    expect(find.text('Kolkata, West Bengal 700016'), findsOneWidget);
  });

  testWidgets('buttons of screens not built yet, and order details, say coming soon',
      (tester) async {
    serve([
      _order('a',
          bucket: FulfilmentBucket.packing, actions: const [SellerOrderAction.continuePacking]),
    ]);
    await pump(tester);

    await tester.tap(find.text('Continue Packing'));
    await tester.pumpAndSettle();
    expect(find.text('This is coming soon'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(ListView))).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Order details'));
    await tester.pumpAndSettle();
    expect(find.text('This is coming soon'), findsOneWidget);
  });

  testWidgets('loads more as the seller scrolls, then shows the footer', (tester) async {
    final first = [for (var i = 0; i < 6; i++) _order('p$i')];
    when(() => repository.orders(page: 0))
        .thenAnswer((_) async => IncomingOrdersPage(items: first, page: 0, hasMore: true));
    when(() => repository.orders(page: 1)).thenAnswer(
        (_) async => IncomingOrdersPage(items: [_order('last')], page: 1, hasMore: false));
    await pump(tester);
    expect(find.textContaining('Showing all'), findsNothing);

    await tester.scrollUntilVisible(find.text('Showing all 7 incoming orders'), 400);

    verify(() => repository.orders(page: 1)).called(1);
    expect(find.text('#VX-last'), findsOneWidget);
  });

  testWidgets('back goes to Profile when the page was opened directly', (tester) async {
    serve(const []);
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.text('profile page'), findsOneWidget);
  });

  testWidgets('reads in Hindi at twice the text size without overflowing', (tester) async {
    await pump(tester, repo: MockSellerOrderRepository(), locale: const Locale('hi'), textScale: 2);

    expect(find.text('आने वाले ऑर्डर'), findsOneWidget);
    expect(find.text('पैकिंग शुरू करें'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('card', () {
    Future<void> pumpCard(WidgetTester tester, IncomingOrder order) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: IncomingOrderCard(order: order, onAction: (_) {}, onDetails: () {}),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('shows the arranging, returning and handed over statuses from tags',
        (tester) async {
      for (final (tag, text) in [
        (OrderTag.arrangingPickup, 'Arranging pickup'),
        (OrderTag.returning, 'Returning to you'),
        (OrderTag.handedOver, 'Handed over'),
      ]) {
        await pumpCard(tester, _order('a', bucket: FulfilmentBucket.shipped, tags: [tag]));
        expect(find.text(text), findsOneWidget);
        expect(find.text('Order Shipped'), findsNothing);
      }
    });

    testWidgets('shows a failed pickup, the scheduled buttons and the booking errors',
        (tester) async {
      await pumpCard(
        tester,
        _order('a',
            bucket: FulfilmentBucket.scheduled,
            tags: const [OrderTag.pickupFailed],
            actions: const [SellerOrderAction.viewSchedule, SellerOrderAction.reschedulePickup]),
      );
      expect(find.text('Pickup Scheduled'), findsOneWidget);
      expect(find.text('Pickup failed'), findsOneWidget);

      await pumpCard(
        tester,
        _order('b',
            bucket: FulfilmentBucket.packing,
            actions: const [SellerOrderAction.schedulePickup],
            bookingError: 'ERROR_SHIPMENT_CREATION_FAILED'),
      );
      expect(find.text('Packing Required'), findsOneWidget);
      expect(find.text('Schedule Pickup'), findsOneWidget);
      expect(find.text('We could not arrange the shipment. Please try again'), findsOneWidget);

      await pumpCard(tester, _order('c', bookingError: 'ERROR_NO_LOGISTICS_AVAILABLE'));
      expect(find.text('No pickup service in your area. Contact support'), findsOneWidget);
    });

    testWidgets('shows a placeholder photo and a buyer without a name', (tester) async {
      await pumpCard(tester, _order('a', buyerName: null));

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.bySemanticsLabel('Item photo'), findsOneWidget);
      expect(find.text('Buyer'), findsOneWidget);
    });

    testWidgets('wraps a long title to two lines', (tester) async {
      await pumpCard(tester, _order('a', title: 'A very long item title ' * 8));

      final title = tester.widget<Text>(find.textContaining('A very long item title'));
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });

  group('initials and counts', () {
    test('take the first letters of the first two words, in any script', () {
      expect(buyerInitials('Ananya Sharma'), 'AS');
      expect(buyerInitials('  priya   iyer  nair '), 'PI');
      expect(buyerInitials('Madonna'), 'M');
      expect(buyerInitials('अनन्या शर्मा'), 'अश');
      expect(buyerInitials(null), '');
    });

    test('a badge shows 99+ above 99', () {
      expect(cappedCount(99), '99');
      expect(cappedCount(100), '99+');
    });
  });
}
