import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/plan_selection.dart';
import 'package:valuex_mobile/features/listing/domain/seller_plan.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_error_messages.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_plan_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/plan_selection_controller.dart';
import 'package:valuex_mobile/features/listing/presentation/review_listing_screen.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/payment/domain/payment_checkout.dart';
import 'package:valuex_mobile/features/payment/domain/payment_status.dart';
import 'package:valuex_mobile/features/payment/presentation/payment_flow.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';

class _MockListingRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

class _MockPaymentFlow extends Mock implements PaymentFlow {}

class _FakeContext extends Fake implements BuildContext {}

const _checkout = CheckoutRequest(
  paymentId: 'p1',
  orderId: 'order-1',
  amount: 149,
  currency: 'INR',
  publicKey: 'mock_public_key',
);

const _paid = PlanSelection(
  planCode: 'BOOSTED',
  paymentRequired: true,
  listingStatus: 'PLAN_PAYMENT_PENDING',
  amount: 149,
  checkout: _checkout,
);

const _free = PlanSelection(
  planCode: 'BOOSTED',
  paymentRequired: false,
  listingStatus: 'PLAN_PAYMENT_SUCCESS',
  amount: 0,
);

const _summary = ListingSummary(
  title: 'Wooden chair',
  categoryPath: 'Furniture > Chairs',
  price: '500',
  description: 'A sturdy chair',
);

final _plan = SellerPlan.fromJson({
  'code': 'BOOSTED',
  'name': 'Boosted',
  'originalPrice': 399,
  'discountedPrice': 149,
  'discountAmount': 250,
  'discountPercent': 63,
  'validityDays': 7,
  'supportLevel': 'AI_EMAIL_CHAT',
  'features': ['Listed on top when searched'],
  'badge': 'POPULAR',
  'recommended': true,
  'priceIncludesGst': true,
  'gstRatePercent': 18,
  'gstAmount': 22.73,
  'totalAmount': 149,
});

Map<String, dynamic> _paidJson() => {
      'planCode': 'BOOSTED',
      'paymentRequired': true,
      'listingStatus': 'PLAN_PAYMENT_PENDING',
      'amount': 149.0,
      'payment': {
        'paymentId': 'p1',
        'orderId': 'order-1',
        'amount': 149.0,
        'currency': 'INR',
        'publicKey': 'mock_public_key',
        'expiresAt': '2026-10-31T10:30:00Z',
      },
    };

void main() {
  setUpAll(() async {
    await loadBrandFonts();
    registerFallbackValue(_FakeContext());
    registerFallbackValue(_checkout);
  });

  group('PlanSelection', () {
    test('reads a paid answer with its checkout details', () {
      final selection = PlanSelection.fromJson(_paidJson());

      expect(selection.paymentRequired, isTrue);
      expect(selection.amount, 149);
      expect(selection.listingStatus, 'PLAN_PAYMENT_PENDING');
      expect(selection.checkout?.orderId, 'order-1');
      expect(selection.checkout?.paymentId, 'p1');
    });

    test('reads a free answer without a checkout', () {
      final selection = PlanSelection.fromJson({
        'planCode': 'X',
        'paymentRequired': false,
        'listingStatus': 'PLAN_PAYMENT_SUCCESS',
        'amount': 0,
        'payment': null,
      });

      expect(selection.paymentRequired, isFalse);
      expect(selection.checkout, isNull);
    });
  });

  group('repository', () {
    test('posts the plan code and parses the answer', () async {
      final api = FakeHttpAdapter((_) async => FakeHttpAdapter.ok(_paidJson()));
      final repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
        Dio(),
      );

      final selection = await repository.selectPlan('l1', 'BOOSTED');

      expect(api.requests.single.method, 'POST');
      expect(api.requests.single.path, '/listings/l1/plan-selection');
      expect(api.requests.single.data, {'planCode': 'BOOSTED'});
      expect(selection.checkout?.amount, 149);
    });
  });

  group('controller', () {
    late _MockListingRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _MockListingRepository();
      container = ProviderContainer(
        overrides: [listingRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.listen(planSelectionControllerProvider, (_, __) {});
    });

    PlanSelectionController controller() => container.read(planSelectionControllerProvider.notifier);

    test('returns the selection', () async {
      when(() => repository.selectPlan('l1', 'BOOSTED')).thenAnswer((_) async => _paid);

      final result = await controller().select('l1', 'BOOSTED');

      expect(result.outcome, PlanSelectionOutcome.selected);
      expect(result.selection, _paid);
      expect(container.read(planSelectionControllerProvider), isFalse);
    });

    test('tells the screen when Aadhaar verification is needed', () async {
      when(() => repository.selectPlan(any(), any())).thenThrow(const ApiError(
        type: ApiErrorType.business,
        message: 'verify',
        code: 'AADHAAR_VERIFICATION_REQUIRED',
        statusCode: 403,
      ));

      final result = await controller().select('l1', 'BOOSTED');

      expect(result.outcome, PlanSelectionOutcome.aadhaarRequired);
    });

    test('returns any other error', () async {
      const error = ApiError(type: ApiErrorType.business, message: 'x', code: 'ERROR_INCOMPLETE_LISTING');
      when(() => repository.selectPlan(any(), any())).thenThrow(error);

      final result = await controller().select('l1', 'BOOSTED');

      expect(result.outcome, PlanSelectionOutcome.failed);
      expect(result.error, error);
    });

    test('is busy while the request runs', () async {
      when(() => repository.selectPlan(any(), any())).thenAnswer((_) async {
        expect(container.read(planSelectionControllerProvider), isTrue);
        return _paid;
      });

      await controller().select('l1', 'BOOSTED');

      expect(container.read(planSelectionControllerProvider), isFalse);
    });
  });

  group('error messages', () {
    final l10n = AppLocalizationsEn();

    test('maps the plan selection and payment codes', () {
      expect(listingCodeMessage(l10n, 'ERROR_INCOMPLETE_LISTING'), l10n.sellErrorIncomplete);
      expect(listingCodeMessage(l10n, 'ERROR_MAX_LISTINGS_REACHED'), l10n.sellErrorMaxListings);
      expect(listingCodeMessage(l10n, 'PLAN_NOT_FOUND'), l10n.planErrorNotAvailable);
      expect(listingCodeMessage(l10n, 'ERROR_PLAN_SELECTION_NOT_ALLOWED'), l10n.planErrorNotAvailable);
      expect(listingCodeMessage(l10n, 'ERROR_GATEWAY_UNAVAILABLE'), l10n.paymentErrorGatewayUnavailable);
      expect(listingCodeMessage(l10n, 'SOMETHING_ELSE'), isNull);
    });
  });

  group('screens', () {
    late _MockListingRepository repository;
    late _MockPaymentFlow flow;

    setUp(() {
      repository = _MockListingRepository();
      flow = _MockPaymentFlow();
      when(() => repository.sellerPlans()).thenAnswer((_) async => [_plan]);
    });

    Future<AppHarness> open(
      WidgetTester tester,
      Object extra,
      String route, {
      double textScale = 1,
      Locale? locale,
    }) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      final harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        paymentFlowProvider.overrideWithValue(flow),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await harness.launch(location: RouteNames.home);
      tester.view.physicalSize = Size(1080, 1800 * textScale * 3);
      harness.container.read(appRouterProvider).go(route, extra: extra);
      await harness.settle();
      return harness;
    }

    Future<AppHarness> openReview(WidgetTester tester, PlanSelection selection, {double textScale = 1}) {
      return open(
        tester,
        ReviewArgs(listingId: 'l1', summary: _summary, plan: _plan, selection: selection),
        RouteNames.sellReview,
        textScale: textScale,
      );
    }

    Future<AppHarness> openPlan(WidgetTester tester) =>
        open(tester, const PlanArgs(listingId: 'l1', summary: _summary), RouteNames.sellPlan);

    group('plan page', () {
      testWidgets('Review Listing chooses the plan on the server and opens the review page', (tester) async {
        when(() => repository.selectPlan('l1', 'BOOSTED')).thenAnswer((_) async => _paid);
        final harness = await openPlan(tester);

        await tester.tap(find.text('Review Listing'));
        await harness.settle();

        verify(() => repository.selectPlan('l1', 'BOOSTED')).called(1);
        expect(find.byType(ReviewListingScreen), findsOneWidget);
        expect(find.byType(ListingPlanScreen), findsNothing);
        await harness.dispose();
      });

      testWidgets('shows the reason when the plan cannot be chosen and stays on the page', (tester) async {
        when(() => repository.selectPlan(any(), any())).thenThrow(const ApiError(
          type: ApiErrorType.business,
          message: 'x',
          code: 'ERROR_MAX_LISTINGS_REACHED',
        ));
        final harness = await openPlan(tester);

        await tester.tap(find.text('Review Listing'));
        await harness.settle();

        expect(find.text("You've reached the maximum listing limit"), findsOneWidget);
        expect(find.byType(ListingPlanScreen), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('asks for Aadhaar verification when the seller has not done it', (tester) async {
        when(() => repository.selectPlan(any(), any())).thenThrow(const ApiError(
          type: ApiErrorType.business,
          message: 'verify',
          code: 'AADHAAR_VERIFICATION_REQUIRED',
          statusCode: 403,
        ));
        final harness = await openPlan(tester);

        await tester.tap(find.text('Review Listing'));
        await harness.settle();

        expect(find.text('Please complete Aadhaar verification to proceed'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('opening the page without a draft goes back to the first sell step', (tester) async {
        final harness = await open(tester, 'not-args', RouteNames.sellPlan);

        expect(find.byType(ListingPlanScreen), findsNothing);
        await harness.dispose();
      });
    });

    group('review page', () {
      testWidgets('shows the item, the plan, the breakdown, the note and the pay button', (tester) async {
        final harness = await openReview(tester, _paid);

        expect(find.text('Review & Publish'), findsOneWidget);
        expect(find.text('Wooden chair'), findsOneWidget);
        expect(find.text('Furniture > Chairs'), findsOneWidget);
        expect(find.text('₹500'), findsOneWidget);
        expect(find.text('A sturdy chair'), findsOneWidget);
        expect(find.text('Boosted'), findsOneWidget);
        expect(find.text('Valid for 7 days'), findsOneWidget);
        expect(find.text('Inclusive of GST'), findsOneWidget);
        expect(find.textContaining('Trust & Safety team'), findsOneWidget);
        expect(find.text('Pay ₹149 & Publish'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('a plan priced at zero shows Publish without an amount and goes on without a checkout',
          (tester) async {
        final harness = await openReview(tester, _free);

        expect(find.text('Publish'), findsOneWidget);
        expect(find.textContaining('Pay ₹'), findsNothing);
        await tester.tap(find.text('Publish'));
        await harness.settle();

        verifyNever(() => flow.start(any(), any()));
        expect(find.text('Your listing is under review'), findsOneWidget);
        expect(find.byType(ReviewListingScreen), findsNothing);
        await harness.dispose();
      });

      testWidgets('a confirmed payment says it was received and leaves the page', (tester) async {
        when(() => flow.start(any(), any())).thenAnswer((_) async => PaymentResult.confirmed);
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        verify(() => flow.start(any(), _checkout)).called(1);
        expect(find.text('Payment received, your listing is under review'), findsOneWidget);
        expect(find.byType(ReviewListingScreen), findsNothing);
        await harness.dispose();
      });

      testWidgets('a payment the server has not settled yet says it is being confirmed', (tester) async {
        when(() => flow.start(any(), any())).thenAnswer((_) async => PaymentResult.pending);
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        expect(find.text("We're confirming your payment"), findsOneWidget);
        expect(find.byType(ReviewListingScreen), findsNothing);
        await harness.dispose();
      });

      testWidgets('a cancelled checkout stays on the page and keeps the same order', (tester) async {
        when(() => flow.start(any(), any())).thenAnswer((_) async => PaymentResult.cancelled);
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();
        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        expect(find.byType(ReviewListingScreen), findsOneWidget);
        verify(() => flow.start(any(), _checkout)).called(2);
        verifyNever(() => repository.selectPlan(any(), any()));
        await harness.dispose();
      });

      testWidgets('a failed payment says so and the next try asks for a new order', (tester) async {
        final retry = PlanSelection.fromJson({
          ..._paidJson(),
          'payment': {..._paidJson()['payment'] as Map<String, dynamic>, 'orderId': 'order-2', 'paymentId': 'p2'},
        });
        var calls = 0;
        when(() => flow.start(any(), any())).thenAnswer((_) async {
          return calls++ == 0 ? PaymentResult.failed : PaymentResult.cancelled;
        });
        when(() => repository.selectPlan('l1', 'BOOSTED')).thenAnswer((_) async => retry);
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();
        expect(find.text('Your payment did not go through. You have not been charged.'), findsOneWidget);
        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        verify(() => repository.selectPlan('l1', 'BOOSTED')).called(1);
        final started = verify(() => flow.start(any(), captureAny())).captured;
        expect((started.last as CheckoutRequest).orderId, 'order-2');
        await harness.dispose();
      });

      testWidgets('shows why a new order could not be made and does not open the checkout', (tester) async {
        when(() => flow.start(any(), any())).thenAnswer((_) async => PaymentResult.failed);
        when(() => repository.selectPlan(any(), any())).thenThrow(const ApiError(
          type: ApiErrorType.server,
          message: 'down',
          code: 'ERROR_GATEWAY_UNAVAILABLE',
        ));
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();
        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        expect(find.text('Payments are not available at this moment, please try again later'), findsOneWidget);
        verify(() => flow.start(any(), any())).called(1);
        await harness.dispose();
      });

      testWidgets('asks for Aadhaar when a new order is refused for that', (tester) async {
        when(() => flow.start(any(), any())).thenAnswer((_) async => PaymentResult.failed);
        when(() => repository.selectPlan(any(), any())).thenThrow(const ApiError(
          type: ApiErrorType.business,
          message: 'verify',
          code: 'AADHAAR_VERIFICATION_REQUIRED',
        ));
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();
        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        expect(find.text('Please complete Aadhaar verification to proceed'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('a new order for a plan that now costs nothing finishes without a checkout', (tester) async {
        when(() => flow.start(any(), any())).thenAnswer((_) async => PaymentResult.failed);
        when(() => repository.selectPlan(any(), any())).thenAnswer((_) async => _free);
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();
        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        verify(() => flow.start(any(), any())).called(1);
        expect(find.text('Your listing is under review'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('shows the error when the checkout cannot open', (tester) async {
        when(() => flow.start(any(), any())).thenThrow(const ApiError(
          type: ApiErrorType.server,
          message: 'down',
          code: 'ERROR_GATEWAY_UNAVAILABLE',
        ));
        final harness = await openReview(tester, _paid);

        await tester.tap(find.text('Pay ₹149 & Publish'));
        await harness.settle();

        expect(find.text('Payments are not available at this moment, please try again later'), findsOneWidget);
        expect(find.byType(ReviewListingScreen), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('meets the tap target and label guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        final harness = await openReview(tester, _paid);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
        await harness.dispose();
      });

      testWidgets('lays out without overflow at 2x text size', (tester) async {
        final harness = await openReview(tester, _paid, textScale: 2);

        expect(tester.takeException(), isNull);
        expect(find.text('Review & Publish'), findsOneWidget);
        await harness.dispose();
      });
    });
  });
}
