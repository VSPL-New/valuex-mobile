import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/existing_listing.dart';
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';
import 'package:valuex_mobile/features/listing/domain/restricted_check.dart';
import 'package:valuex_mobile/features/listing/presentation/item_details_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_plan_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_submitted_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/item_details_controller.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/notifications/domain/app_notification.dart';
import 'package:valuex_mobile/features/notifications/domain/notification_deep_links.dart';
import 'package:valuex_mobile/features/notifications/presentation/notification_text.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';
import '../listing/listing_fixtures.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

class _MockListings extends Mock implements ListingRepository {}

class _FakeDraft extends Fake implements ListingDetailsDraft {}

class _FakeSchema extends Fake implements ListingSchema {}

class _FakeLocation extends HomeLocationController {
  @override
  Future<HomeLocationState> build() async => const LocationNeeded(LocationNeed.notAsked);
}

final _en = AppLocalizationsEn();
final _hi = AppLocalizationsHi();

AppNotification _n(
  String eventType, {
  Map<String, dynamic> params = const {},
  String title = 'Server title',
  String body = 'Server body',
  String? deepLink,
}) =>
    AppNotification(
      id: 'n-$eventType',
      eventType: eventType,
      title: title,
      body: body,
      deepLink: deepLink,
      params: params,
      priority: NotificationPriority.high,
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

Map<String, dynamic> _listingJson({
  String status = 'REVISION_REQUIRED',
  Object? price = 1200.0,
  Map<String, dynamic>? attributes,
}) =>
    {
      'listingId': 'l1',
      'status': status,
      'images': [],
      'title': 'Blue bike',
      'category': {
        'code': 'CAT-1',
        'name': 'Android Phones',
        'marketplaceStatus': 'ALLOWED',
        'path': [
          {'code': 'L1-M', 'name': 'Mobiles & Tablets', 'level': 1},
          {'code': 'L2-S', 'name': 'Smartphones', 'level': 2},
          {'code': 'CAT-1', 'name': 'Android Phones', 'level': 3},
        ],
      },
      'condition': 'GOOD',
      'conditionNotes': 'Small scratch',
      'description': 'Works well',
      'price': price,
      'negotiable': true,
      'quantity': 2,
      'attributes': attributes ??
          {'brand': 'Acme', 'storage_gb': '64_GB', 'battery_health_pct': 90.5, 'age_months': 12},
      'location': 'Pune',
      'planCode': null,
    };

ExistingListing _listing({String status = 'REVISION_REQUIRED'}) =>
    ExistingListing.fromJson(_listingJson(status: status));

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDraft());
    registerFallbackValue(_FakeSchema());
    loadBrandFonts();
  });

  group('listing message text', () {
    test('every listing event shows its own English and Hindi title', () {
      const types = [
        'LISTING_UNDER_REVIEW',
        'LISTING_PUBLISHED',
        'LISTING_REVISION_REQUIRED',
        'LISTING_REJECTED_FINAL',
        'LISTING_REFUND_DUE',
        'LISTING_PAYMENT_FAILED',
        'LISTING_EXPIRED',
        'LISTING_REMOVED_BY_ADMIN',
      ];
      for (final type in types) {
        expect(notificationTitle(_en, _n(type)), isNot('Server title'), reason: type);
        expect(notificationTitle(_hi, _n(type)), isNot('Server title'), reason: type);
        expect(notificationTitle(_hi, _n(type)), isNot(notificationTitle(_en, _n(type))),
            reason: type);
      }
    });

    test('published and expired use the listing title', () {
      expect(
        notificationBody(_en, _n('LISTING_PUBLISHED', params: {'title': 'Blue bike'})),
        'Your listing "Blue bike" is now live. Buyers can find it.',
      );
      expect(
        notificationBody(_hi, _n('LISTING_PUBLISHED', params: {'title': 'Blue bike'})),
        contains('Blue bike'),
      );
      expect(
        notificationBody(_en, _n('LISTING_EXPIRED', params: {'title': 'Blue bike'})),
        'Your listing "Blue bike" has expired. Renew it to make it visible again.',
      );
    });

    test('needs changes shows the reason and the review count of an initial review', () {
      final params = {'title': 'Blue bike', 'reason': 'Photos are blurry', 'attempt': 2};

      expect(
        notificationBody(_en, _n('LISTING_REVISION_REQUIRED', params: params)),
        'Your listing "Blue bike" needs changes: Photos are blurry. Update it and resubmit '
        '(review 2 of 3). You will not be charged again.',
      );
      expect(
        notificationBody(_hi, _n('LISTING_REVISION_REQUIRED', params: params)),
        contains('2/3'),
      );
    });

    test('needs changes after an edit has no review count', () {
      final body = notificationBody(
        _en,
        _n('LISTING_REVISION_REQUIRED', params: {'title': 'Blue bike', 'reason': 'Wrong price'}),
      );

      expect(body, isNot(contains('of 3')));
      expect(body, contains('Wrong price'));
    });

    test('final rejection mentions the refund only when there is an amount', () {
      expect(
        notificationBody(
            _en, _n('LISTING_REJECTED_FINAL', params: {'title': 'Bike', 'amount': '49'})),
        'Your listing "Bike" was not approved after 3 reviews. Your plan fee of ₹49 will be refunded.',
      );
      expect(
        notificationBody(_en, _n('LISTING_REJECTED_FINAL', params: {'title': 'Bike'})),
        'Your listing "Bike" was not approved after 3 reviews.',
      );
    });

    test('refund, payment failed, under review and removed read as the story says', () {
      expect(notificationBody(_en, _n('LISTING_REFUND_DUE', params: {'amount': '49.50'})),
          'Your refund of ₹49.50 for the listing plan is being processed.');
      expect(notificationBody(_en, _n('LISTING_PAYMENT_FAILED')),
          'Your payment was unsuccessful. Please try again or choose another plan.');
      expect(notificationBody(_en, _n('LISTING_UNDER_REVIEW')),
          'Payment received. Your listing is under review and will be checked within a few hours.');
      expect(notificationBody(_en, _n('LISTING_REMOVED_BY_ADMIN', params: {'title': 'Bike'})),
          'Your listing "Bike" was removed by JustQlic. Contact support for details.');
    });

    test('a message without its values, an old row and other events show the server text', () {
      expect(notificationBody(_en, _n('LISTING_PUBLISHED')), 'Server body');
      expect(notificationBody(_en, _n('LISTING_REVISION_REQUIRED', params: {'title': 'x'})),
          'Server body');
      expect(notificationBody(_en, _n('LISTING_REFUND_DUE')), 'Server body');
      expect(notificationBody(_en, _n('ACCOUNT_CREATED')), 'Server body');
      expect(notificationTitle(_en, _n('ACCOUNT_CREATED')), 'Server title');
      expect(notificationBody(_en, _n('LISTING_BOOSTED_SOON')), 'Server body');
    });

    test('the three action-needed listing events are alerts', () {
      expect(_n('LISTING_REVISION_REQUIRED').isAlert, isTrue);
      expect(_n('LISTING_REJECTED_FINAL').isAlert, isTrue);
      expect(_n('LISTING_REMOVED_BY_ADMIN').isAlert, isTrue);
      expect(_n('LISTING_PUBLISHED').isAlert, isFalse);
      expect(notificationCategoryOf('LISTING_PAYMENT_FAILED'), NotificationCategory.listings);
    });

    test('copyWith keeps the values', () {
      final copy = _n('LISTING_PUBLISHED', params: {'title': 'Bike'}).copyWith(read: true);

      expect(copy.read, isTrue);
      expect(copy.params, {'title': 'Bike'});
    });
  });

  group('listing deep links', () {
    test('needs changes opens Item Details with the listing id', () {
      final target = notificationTargetFor('/sell/details?listingId=abc')!;

      expect(target.route, RouteNames.sellDetails);
      expect(target.listingId, 'abc');
      expect(target.needsListing, isTrue);
      expect(target.isTab, isFalse);
    });

    test('payment failed and renew open plan selection with the listing id', () {
      final target = notificationTargetFor('/sell/plan?listingId=abc')!;

      expect(target.route, RouteNames.sellPlan);
      expect(target.listingId, 'abc');
    });

    test('a listing link without an id, or the not-yet-built pages, have no target', () {
      expect(notificationTargetFor('/sell/plan'), isNull);
      expect(notificationTargetFor('/sell/details?listingId='), isNull);
      expect(notificationTargetFor('/listing/abc'), isNull);
      expect(notificationTargetFor('/support'), isNull);
    });

    test('the profile links still work and need no listing', () {
      expect(notificationTargetFor('/profile')!.needsListing, isFalse);
    });
  });

  group('ExistingListing', () {
    test('reads the stored listing the way the form keeps it', () {
      final listing = _listing();

      expect(listing.listingId, 'l1');
      expect(listing.status, 'REVISION_REQUIRED');
      expect(listing.city, 'Pune');
      expect(listing.category!.code, 'CAT-1');
      final draft = listing.draft;
      expect(draft.title, 'Blue bike');
      expect(draft.categoryCode, 'CAT-1');
      expect(draft.condition, ListingCondition.good);
      expect(draft.conditionNotes, 'Small scratch');
      expect(draft.description, 'Works well');
      expect(draft.price, '1200');
      expect(draft.negotiable, isTrue);
      expect(draft.quantity, '2');
      expect(draft.attributes['brand'], 'Acme');
    });

    test('a price with paise keeps two decimals and a missing one is empty', () {
      expect(ExistingListing.fromJson(_listingJson(price: 49.5)).draft.price, '49.50');
      expect(ExistingListing.fromJson(_listingJson(price: null)).draft.price, '');
    });

    test('a listing without category, quantity or attributes still loads', () {
      final listing = ExistingListing.fromJson({'listingId': 'l2', 'status': 'DRAFT'});

      expect(listing.category, isNull);
      expect(listing.draft.categoryCode, isNull);
      expect(listing.draft.quantity, '1');
      expect(listing.draft.attributes, isEmpty);
      expect(listing.city, '');
    });

    test('only a listing that needs changes is a revision', () {
      expect(ItemDetailsArgs(listingId: 'l1', existing: _listing()).isRevision, isTrue);
      expect(ItemDetailsArgs(listingId: 'l1', existing: _listing(status: 'DRAFT')).isRevision,
          isFalse);
      expect(const ItemDetailsArgs(listingId: 'l1').isRevision, isFalse);
    });
  });

  group('listing repository', () {
    late FakeHttpAdapter adapter;
    late ListingRepository repository;

    setUp(() {
      adapter = FakeHttpAdapter((options) async {
        if (options.method == 'GET' && options.path == '/listings/l1') {
          return FakeHttpAdapter.ok(_listingJson());
        }
        return FakeHttpAdapter.ok(null);
      });
      repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig,
            adapter: adapter),
        Dio(),
      );
    });

    test('loads one listing from GET /listings/{id}', () async {
      final listing = await repository.getListing('l1');

      expect(listing.draft.title, 'Blue bike');
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/listings/l1');
    });

    test('resubmits with POST /listings/{id}/trust-safety-review', () async {
      await repository.resubmitForReview('l1');

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/listings/l1/trust-safety-review');
    });
  });

  group('screens', () {
    late _MockNotifications notifications;
    late _MockListings listings;
    late AppHarness harness;

    setUp(() {
      listings = _MockListings();
      when(() => listings.listingSchema(any())).thenAnswer((_) async => phoneSchema);
      when(() => listings.sellerPlans()).thenAnswer((_) async => []);
      when(() => listings.saveDetails(any(), any(), any(), city: any(named: 'city')))
          .thenAnswer((_) async {});
      when(() => listings.checkRestrictedItems(any())).thenAnswer(
          (_) async => const RestrictedCheck(checkId: 'c1', result: RestrictedResult.safe));
      when(() => listings.resubmitForReview(any())).thenAnswer((_) async {});
    });

    Future<void> openList(WidgetTester tester, List<AppNotification> items) async {
      notifications = _MockNotifications();
      when(() => notifications.page(0)).thenAnswer((_) async =>
          NotificationsPage(items: items, page: 0, hasMore: false, unread: items.length));
      when(notifications.unreadCount).thenAnswer((_) async => items.length);
      when(() => notifications.markRead(any())).thenAnswer((_) async {});
      harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(listings),
        homeLocationControllerProvider.overrideWith(_FakeLocation.new),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      tester.view.physicalSize = const Size(1080, 4800);
      await harness.launch(location: RouteNames.notifications);
    }

    testWidgets('the list shows listing messages in the user language with their values',
        (tester) async {
      await openList(tester, [
        _n('LISTING_PUBLISHED', params: {'title': 'Blue bike'}),
        _n('LISTING_REFUND_DUE', params: {'amount': '49'}),
      ]);

      expect(find.text('Your listing is live'), findsOneWidget);
      expect(
          find.text('Your listing "Blue bike" is now live. Buyers can find it.'), findsOneWidget);
      expect(find.text('Refund is being processed'), findsOneWidget);
      expect(
          find.text('Your refund of ₹49 for the listing plan is being processed.'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('needs changes opens Item Details filled with the stored listing', (tester) async {
      when(() => listings.getListing('l1')).thenAnswer((_) async => _listing());
      await openList(tester, [
        _n('LISTING_REVISION_REQUIRED',
            params: {'title': 'Blue bike', 'reason': 'Photos are blurry', 'attempt': 1},
            deepLink: '/sell/details?listingId=l1'),
      ]);

      await tester.tap(find.text('Your listing needs changes'));
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text('Blue bike'), findsOneWidget);
      expect(find.text('Resubmit for review'), findsOneWidget);
      expect(find.text('Choose Listing Plan'), findsNothing);
      verify(() => listings.listingSchema('CAT-1')).called(1);
      verifyNever(() => listings.setCategory(any(), any()));
      verify(() => notifications.markRead('n-LISTING_REVISION_REQUIRED')).called(1);
      await harness.dispose();
    });

    testWidgets('Resubmit saves, checks the item and sends it back to review without payment',
        (tester) async {
      when(() => listings.getListing('l1')).thenAnswer((_) async => _listing());
      await openList(tester, [
        _n('LISTING_REVISION_REQUIRED',
            params: {'title': 'Blue bike', 'reason': 'Photos are blurry', 'attempt': 1},
            deepLink: '/sell/details?listingId=l1'),
      ]);
      await tester.tap(find.text('Your listing needs changes'));
      await harness.settle();

      await tester.tap(find.text('Resubmit for review'));
      await harness.settle();

      verify(() => listings.saveDetails('l1', any(), any(), city: any(named: 'city'))).called(1);
      verify(() => listings.checkRestrictedItems('l1')).called(1);
      verify(() => listings.resubmitForReview('l1')).called(1);
      verifyNever(() => listings.sellerPlans());
      expect(find.byType(ListingSubmittedScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a refused resubmission stays on the page and says why', (tester) async {
      when(() => listings.getListing('l1')).thenAnswer((_) async => _listing());
      when(() => listings.resubmitForReview(any()))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
      await openList(tester, [
        _n('LISTING_REVISION_REQUIRED',
            params: {'title': 'Blue bike', 'reason': 'x', 'attempt': 1},
            deepLink: '/sell/details?listingId=l1'),
      ]);
      await tester.tap(find.text('Your listing needs changes'));
      await harness.settle();

      await tester.tap(find.text('Resubmit for review'));
      await harness.settle();

      expect(find.byType(ListingSubmittedScreen), findsNothing);
      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('payment unsuccessful opens plan selection for that listing', (tester) async {
      when(() => listings.getListing('l1'))
          .thenAnswer((_) async => _listing(status: 'PLAN_PAYMENT_FAILED'));
      await openList(tester, [
        _n('LISTING_PAYMENT_FAILED', deepLink: '/sell/plan?listingId=l1'),
      ]);

      await tester.tap(find.text('Payment unsuccessful').first);
      await harness.settle();

      expect(find.byType(ListingPlanScreen), findsOneWidget);
      final args = tester.widget<ListingPlanScreen>(find.byType(ListingPlanScreen)).args;
      expect(args.listingId, 'l1');
      expect(args.summary.title, 'Blue bike');
      expect(args.summary.categoryPath, 'Mobiles & Tablets > Smartphones > Android Phones');
      expect(args.summary.price, '1200');
      expect(args.summary.conditionLabel, 'Good');
      expect(args.summary.city, 'Pune');
      verify(() => listings.sellerPlans()).called(1);
      await harness.dispose();
    });

    testWidgets('a listing that is no longer in the right state says so', (tester) async {
      when(() => listings.getListing('l1')).thenAnswer((_) async => _listing(status: 'PUBLISHED'));
      await openList(tester, [
        _n('LISTING_REVISION_REQUIRED',
            params: {'title': 'Blue bike', 'reason': 'x', 'attempt': 1},
            deepLink: '/sell/details?listingId=l1'),
      ]);

      await tester.tap(find.text('Your listing needs changes'));
      await harness.settle();

      expect(find.text('This listing can no longer be changed here'), findsOneWidget);
      expect(find.byType(ItemDetailsScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('a deleted listing says it is no longer available', (tester) async {
      when(() => listings.getListing('l1'))
          .thenThrow(const ApiError(type: ApiErrorType.server, message: 'gone', statusCode: 404));
      await openList(tester, [
        _n('LISTING_PAYMENT_FAILED', deepLink: '/sell/plan?listingId=l1'),
      ]);

      await tester.tap(find.text('Payment unsuccessful').first);
      await harness.settle();

      expect(find.text('This listing is no longer available'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failed load shows the usual error and stays on the list', (tester) async {
      when(() => listings.getListing('l1'))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
      await openList(tester, [
        _n('LISTING_PAYMENT_FAILED', deepLink: '/sell/plan?listingId=l1'),
      ]);

      await tester.tap(find.text('Payment unsuccessful').first);
      await harness.settle();

      expect(find.byType(ListingPlanScreen), findsNothing);
      expect(find.text('Payment unsuccessful'), findsWidgets);
      await harness.dispose();
    });

    testWidgets('the listing and support links that are not built say coming soon', (tester) async {
      await openList(tester, [
        _n('LISTING_PUBLISHED', params: {'title': 'Blue bike'}, deepLink: '/listing/l1'),
      ]);

      await tester.tap(find.text('Your listing is live'));
      await harness.settle();

      expect(find.text('This is coming soon'), findsOneWidget);
      verifyNever(() => listings.getListing(any()));
      await harness.dispose();
    });

    testWidgets('listing messages pass the tap target, label and contrast guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openList(tester, [
        _n('LISTING_REVISION_REQUIRED',
            params: {'title': 'Blue bike', 'reason': 'Photos are blurry', 'attempt': 1},
            deepLink: '/sell/details?listingId=l1'),
        _n('LISTING_PUBLISHED', params: {'title': 'Blue bike'}),
      ]);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('listing messages do not overflow at large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openList(tester, [
        _n('LISTING_REJECTED_FINAL',
            params: {'title': 'A very long title ' * 4, 'amount': '49'}, deepLink: '/support'),
      ]);

      expect(tester.takeException(), isNull);
      await harness.dispose();
    });
  });

  group('Item Details of an existing listing', () {
    late _MockNotifications notifications;
    late _MockListings listings;

    setUp(() {
      listings = _MockListings();
      when(() => listings.listingSchema(any())).thenAnswer((_) async => phoneSchema);
      when(() => listings.setCategory(any(), any())).thenAnswer((_) async {});
      notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
    });

    Future<AppHarness> open(WidgetTester tester, ExistingListing existing) async {
      final harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(listings),
        homeLocationControllerProvider.overrideWith(_FakeLocation.new),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: RouteNames.home);
      tester.view.physicalSize = const Size(1080, 6400);
      harness.container.read(appRouterProvider).go(
            RouteNames.sellDetails,
            extra: ItemDetailsArgs(listingId: existing.listingId, existing: existing),
          );
      await harness.settle();
      return harness;
    }

    testWidgets('numbers come back as typed text and the form is ready to resubmit',
        (tester) async {
      final harness = await open(tester, _listing());

      final state = harness.container.read(
          itemDetailsControllerProvider(ItemDetailsArgs(listingId: 'l1', existing: _listing())));
      expect(state.schemaStatus, SchemaStatus.ready);
      expect(state.draft.attributes['battery_health_pct'], '90.5');
      expect(state.draft.attributes['age_months'], '12');
      expect(state.canContinue, isTrue);
      await harness.dispose();
    });

    testWidgets('a failed form load can be retried without filing the category again',
        (tester) async {
      var calls = 0;
      when(() => listings.listingSchema(any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const ApiError(type: ApiErrorType.network, message: 'offline');
        }
        return phoneSchema;
      });
      final harness = await open(tester, _listing());
      final args = ItemDetailsArgs(listingId: 'l1', existing: _listing());
      final provider = itemDetailsControllerProvider(args);
      expect(harness.container.read(provider).schemaStatus, SchemaStatus.failed);

      await harness.container.read(provider.notifier).retryCategory();

      expect(harness.container.read(provider).schemaStatus, SchemaStatus.ready);
      verifyNever(() => listings.setCategory(any(), any()));
      await harness.dispose();
    });

    testWidgets('choosing another category files it on the listing', (tester) async {
      final harness = await open(tester, _listing());
      final args = ItemDetailsArgs(listingId: 'l1', existing: _listing());
      final provider = itemDetailsControllerProvider(args);

      await harness.container.read(provider.notifier).selectCategory('CAT-2');
      await harness.container.read(provider.notifier).retryCategory();

      verify(() => listings.setCategory('l1', 'CAT-2')).called(2);
      await harness.dispose();
    });

    testWidgets('a listing without a category waits for one to be chosen', (tester) async {
      final existing = ExistingListing.fromJson({'listingId': 'l3', 'status': 'REVISION_REQUIRED'});
      final harness = await open(tester, existing);

      final state = harness.container.read(
          itemDetailsControllerProvider(ItemDetailsArgs(listingId: 'l3', existing: existing)));
      expect(state.schemaStatus, SchemaStatus.none);
      verifyNever(() => listings.listingSchema(any()));
      await harness.dispose();
    });
  });
}
