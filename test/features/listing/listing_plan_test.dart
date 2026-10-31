import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/utils/formatters.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/plan_selection.dart';
import 'package:valuex_mobile/features/listing/domain/seller_plan.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_plan_screen.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

Map<String, dynamic> _json({
  String code = 'BASIC',
  String name = 'Basic',
  num? original = 99,
  num price = 49,
  num discount = 50,
  int percent = 51,
  int days = 7,
  String support = 'AI_EMAIL',
  List<String> features = const ['Listed in chronological order'],
  String? badge,
  bool recommended = false,
  bool inclusive = true,
  num rate = 18,
  num gst = 7.47,
  num total = 49,
}) =>
    {
      'code': code,
      'name': name,
      'originalPrice': original,
      'discountedPrice': price,
      'discountAmount': discount,
      'discountPercent': percent,
      'validityDays': days,
      'supportLevel': support,
      'features': features,
      'badge': badge,
      'recommended': recommended,
      'priceIncludesGst': inclusive,
      'gstRatePercent': rate,
      'gstAmount': gst,
      'totalAmount': total,
    };

const _args = PlanArgs(
  listingId: 'l1',
  summary: ListingSummary(
    title: 'Wooden chair',
    categoryPath: 'Furniture > Chairs',
    price: '500',
    description: 'A sturdy chair',
  ),
);

final _basic = SellerPlan.fromJson(_json());
final _boosted = SellerPlan.fromJson(_json(
  code: 'BOOSTED',
  name: 'Boosted',
  original: 399,
  price: 149,
  discount: 250,
  percent: 63,
  support: 'AI_EMAIL_CHAT',
  features: ['Listed on top when searched'],
  badge: 'POPULAR',
  recommended: true,
  gst: 22.73,
  total: 149,
));
final _priority = SellerPlan.fromJson(_json(
  code: 'PRIORITY',
  name: 'Priority',
  original: 699,
  price: 249,
  discount: 450,
  percent: 64,
  days: 30,
  support: 'AI_EMAIL_CHAT_CALL',
  features: ['Boosted placement', 'Featured on landing page', 'Featured badge'],
  badge: 'BEST_VALUE',
  gst: 37.98,
  total: 249,
));

void main() {
  setUpAll(loadBrandFonts);

  group('SellerPlan', () {
    test('reads every field from the server JSON', () {
      expect(_boosted.code, 'BOOSTED');
      expect(_boosted.originalPrice, 399);
      expect(_boosted.price, 149);
      expect(_boosted.discountAmount, 250);
      expect(_boosted.discountPercent, 63);
      expect(_boosted.validityDays, 7);
      expect(_boosted.features, ['Listed on top when searched']);
      expect(_boosted.badge, 'POPULAR');
      expect(_boosted.recommended, isTrue);
      expect(_boosted.priceIncludesGst, isTrue);
      expect(_boosted.gstAmount, 22.73);
      expect(_boosted.totalAmount, 149);
      expect(_boosted.hasDiscount, isTrue);
      expect(_boosted.isFree, isFalse);
    });

    test('a free plan without an original price, badge or discount', () {
      final free = SellerPlan.fromJson(
          _json(code: 'FREE', original: null, price: 0, discount: 0, percent: 0, gst: 0, total: 0)
            ..remove('badge')
            ..remove('recommended'));

      expect(free.isFree, isTrue);
      expect(free.hasDiscount, isFalse);
      expect(free.badge, isNull);
      expect(free.recommended, isFalse);
    });

    test('keeps the seller choice, else the recommended plan, else the first', () {
      final plans = [_basic, _boosted, _priority];

      expect(effectivePlan(plans, 'PRIORITY'), _priority);
      expect(effectivePlan(plans, null), _boosted);
      expect(effectivePlan(plans, 'GONE'), _boosted);
      expect(effectivePlan([_basic, _priority], null), _basic);
      expect(effectivePlan(const [], null), isNull);
    });
  });

  group('money format', () {
    test('whole rupees have no decimals, others have two', () {
      expect(Formatters.money(49), '₹49');
      expect(Formatters.money(1500), '₹1,500');
      expect(Formatters.money(22.73), '₹22.73');
      expect(Formatters.money(7.5), '₹7.50');
    });
  });

  group('repository', () {
    test('reads the plans from GET /plans/seller', () async {
      final api =
          FakeHttpAdapter((options) async => FakeHttpAdapter.ok([_json(), _json(code: 'X')]));
      final repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
        Dio(),
      );

      final plans = await repository.sellerPlans();

      expect(plans.map((p) => p.code), ['BASIC', 'X']);
      expect(api.requests.single.path, '/plans/seller');
      expect(api.requests.single.method, 'GET');
    });
  });

  group('screen', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
      when(() => repository.sellerPlans()).thenAnswer((_) async => [_basic, _boosted, _priority]);
    });

    Future<AppHarness> open(WidgetTester tester, {double textScale = 1, AppConfig? config}) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      final harness = AppHarness(tester, config: config, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await harness.launch(location: RouteNames.home);
      tester.view.physicalSize = Size(1080, 1800 * textScale * 3);
      harness.container.read(appRouterProvider).go(RouteNames.sellPlan, extra: _args);
      await harness.settle();
      return harness;
    }

    testWidgets('shows every plan from the server and starts on the recommended one', (
      tester,
    ) async {
      final harness = await open(tester);

      expect(find.byType(ListingPlanScreen), findsOneWidget);
      expect(find.text('Choose Listing Plan'), findsOneWidget);
      expect(find.text('Boost your visibility and sell faster'), findsOneWidget);
      for (final name in ['Basic', 'Boosted', 'Priority']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('₹49'), findsOneWidget);
      expect(find.text('₹399'), findsWidgets);
      expect(find.text('POPULAR'), findsOneWidget);
      expect(find.text('BEST VALUE'), findsOneWidget);
      expect(find.text('Listed on top when searched'), findsOneWidget);
      expect(find.text('7 days validity'), findsNWidgets(2));
      expect(find.text('1 month validity'), findsOneWidget);
      expect(find.text('AI + Email support'), findsOneWidget);
      expect(find.text('AI + Email + Chat + On-call support'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('shows the payment breakdown of the selected plan and follows a change', (
      tester,
    ) async {
      final harness = await open(tester);

      expect(find.text('Payment breakdown'), findsOneWidget);
      expect(find.text('Discount (63% off)'), findsOneWidget);
      expect(find.text('−₹250'), findsOneWidget);
      expect(find.text('GST included'), findsOneWidget);
      expect(find.text('₹22.73'), findsOneWidget);
      expect(find.text('Total to pay'), findsOneWidget);
      expect(find.text('Inclusive of GST'), findsOneWidget);

      await tester.tap(find.text('Priority'));
      await harness.settle();

      expect(find.text('Discount (64% off)'), findsOneWidget);
      expect(find.text('−₹450'), findsOneWidget);
      expect(find.text('₹37.98'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a free plan shows Free and no payment wording', (tester) async {
      when(() => repository.sellerPlans()).thenAnswer((_) async => [
            SellerPlan.fromJson(_json(
                code: 'FREE',
                name: 'Starter',
                original: null,
                price: 0,
                discount: 0,
                percent: 0,
                gst: 0,
                total: 0)),
          ]);

      final harness = await open(tester);

      expect(find.text('Free'), findsWidgets);
      expect(find.text('No payment is needed for this plan.'), findsOneWidget);
      expect(find.text('Inclusive of GST'), findsNothing);
      expect(find.textContaining('Discount'), findsNothing);
      await harness.dispose();
    });

    testWidgets(
        'GST added on top shows the rate and the larger total; the first plan is the default', (
      tester,
    ) async {
      when(() => repository.sellerPlans()).thenAnswer((_) async => [
            SellerPlan.fromJson(_json(inclusive: false, gst: 8.82, total: 57.82)),
            _priority,
          ]);

      final harness = await open(tester);

      expect(find.text('GST (18%)'), findsOneWidget);
      expect(find.text('+₹8.82'), findsOneWidget);
      expect(find.text('₹57.82'), findsOneWidget);
      expect(find.text('Inclusive of GST'), findsNothing);
      expect(find.text('Selected'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('unknown badge and support keys do not break the card', (tester) async {
      when(() => repository.sellerPlans()).thenAnswer((_) async => [
            SellerPlan.fromJson(_json(support: 'AI_EMAIL_PHONE', badge: 'NEW_ARRIVAL', days: 3)),
          ]);

      final harness = await open(tester);

      expect(find.text('NEW ARRIVAL'), findsOneWidget);
      expect(find.text('3 days validity'), findsOneWidget);
      expect(find.textContaining('support'), findsNothing);
      await harness.dispose();
    });

    testWidgets('an empty catalog says so and the button does nothing', (tester) async {
      when(() => repository.sellerPlans()).thenAnswer((_) async => []);

      final harness = await open(tester);
      await tester.tap(find.text('Review Listing'));
      await harness.settle();

      expect(find.text('No plans are available right now.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await harness.dispose();
    });

    testWidgets('a failed load can be retried', (tester) async {
      var calls = 0;
      when(() => repository.sellerPlans()).thenAnswer((_) async {
        if (calls++ == 0) throw const ApiError(type: ApiErrorType.network, message: 'offline');
        return [_basic];
      });

      final harness = await open(tester);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      await harness.dispose();
    });

    testWidgets('Dev builds say the plans are under revision until US-119', (tester) async {
      final harness = await open(tester);

      expect(find.text('Plan is under revision until US-119'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('other environments do not show the revision banner', (tester) async {
      final harness = await open(
        tester,
        config: AppConfig.parse(
          env: 'staging',
          apiBaseUrl: 'https://api.example.com/api/v1',
          aadhaarFlow: 'sandbox',
        ),
      );

      expect(find.byType(ListingPlanScreen), findsOneWidget);
      expect(find.text('Plan is under revision until US-119'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the layout holds at 200% text', (tester) async {
      final harness = await open(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Review Listing'), findsOneWidget);
      await harness.dispose();
    });
  });
}
