import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/widgets/single_tone_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing/domain/listing_preview.dart';
import 'package:valuex_mobile/features/listing/domain/listing_preview_fields.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_preview_screen.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';
import 'listing_fixtures.dart';

class _MockRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

class _FakeLocation extends HomeLocationController {
  @override
  Future<HomeLocationState> build() async => const LocationNeeded(LocationNeed.notAsked);
}

const _labels = PreviewLabels(
  yes: 'Yes',
  no: 'No',
  notProvided: 'Not provided',
  quantity: 'Quantity',
  conditionNotes: 'Condition notes',
  formatDate: _formatDate,
);

String _formatDate(DateTime date) => 'D${date.year}-${date.month}-${date.day}';

final _phoneFields = [
  field('brand', 'TEXT', required: true),
  field('storage_gb', 'OPTION', required: true, options: [
    {'code': '64_GB', 'label': '64 GB'},
    {'code': '128_GB', 'label': '128 GB'},
  ]),
  field('battery_health_pct', 'DECIMAL', unit: '%'),
  field('has_box', 'BOOLEAN'),
  field('pincode', 'TEXT'),
  field('accessories', 'MULTI_OPTION', options: [
    {'code': 'CHARGER', 'label': 'Charger'},
    {'code': 'BOX', 'label': 'Box'},
  ]),
  field('purchase_date', 'DATE', section: 'MORE'),
  field('age_months', 'INTEGER', section: 'MORE'),
];

Map<String, dynamic> _json({
  String status = 'PUBLISHED',
  Map<String, dynamic>? attributes,
  Object? schema = _useDefault,
  String? reviewReason,
  String? publishedAt = '2026-11-01T10:00:00Z',
  String? planName = 'Boosted',
  List<Map<String, dynamic>> images = const [],
  int? quantity = 1,
  String conditionNotes = 'No scratches',
  String description = 'Lightly used, with the original box.',
}) =>
    {
      'listingId': 'l1',
      'status': status,
      'images': images,
      'title': 'Apple Watch',
      'category': {
        'code': 'CAT-1',
        'name': 'Smartwatches',
        'marketplaceStatus': 'ALLOWED',
        'path': [
          {'code': 'L1', 'name': 'Electronics', 'level': 1},
          {'code': 'L2', 'name': 'Wearables', 'level': 2},
          {'code': 'CAT-1', 'name': 'Smartwatches', 'level': 3},
        ],
      },
      'condition': 'LIKE_NEW',
      'conditionNotes': conditionNotes,
      'description': description,
      'price': 14500,
      'negotiable': true,
      'quantity': quantity,
      'attributes': attributes ??
          {
            'brand': 'Apple',
            'storage_gb': '128_GB',
            'battery_health_pct': 0,
            'has_box': false,
            'pincode': '',
            'accessories': ['CHARGER', 'BOX'],
            'purchase_date': '2025-03-09',
            'age_months': 6,
            'mystery_key': 'kept',
          },
      'location': 'Bengaluru',
      'planCode': 'BOOSTED',
      'listingSchema': identical(schema, _useDefault) ? schemaJson(fields: _phoneFields) : schema,
      'reviewReason': reviewReason,
      'planName': planName,
      'publishedAt': publishedAt,
    };

const Object _useDefault = Object();

Map<String, String> _asMap(List<PreviewRow> rows) => {for (final row in rows) row.label: row.value};

void main() {
  setUpAll(() {
    registerFallbackValue('');
    loadBrandFonts();
  });

  group('model', () {
    test('reads the saved values and the preview extras', () {
      final data = ListingPreviewData.fromJson(_json(
        status: 'REVISION_REQUIRED',
        reviewReason: '  Add a clearer photo ',
        images: [
          {'imageId': 'i1', 'mediaId': 'm1', 'sortOrder': 0},
        ],
      ));

      expect(data.title, 'Apple Watch');
      expect(data.price, 14500);
      expect(data.quantity, 1);
      expect(data.city, 'Bengaluru');
      expect(data.reviewReason, 'Add a clearer photo');
      expect(data.images.single.mediaId, 'm1');
      expect(data.schema?.fields, hasLength(_phoneFields.length));
      expect(data.publishedAt, DateTime.utc(2026, 11, 1, 10));
    });

    test('keeps a missing quantity missing instead of defaulting it to 1', () {
      final data = ListingPreviewData.fromJson(_json(quantity: null));

      expect(data.quantity, isNull);
    });

    test('blank extras read as absent and the plan badge needs a publication date', () {
      final data = ListingPreviewData.fromJson(
          _json(reviewReason: '  ', planName: ' ', publishedAt: null, schema: null));

      expect(data.reviewReason, isNull);
      expect(data.planName, isNull);
      expect(data.schema, isNull);
      final unpublished = ListingPreviewData.fromJson(_json(publishedAt: null));
      expect(unpublished.planName, 'Boosted');
      expect(unpublished.planBadge, isNull);
      expect(ListingPreviewData.fromJson(_json()).planBadge, 'Boosted');
    });

    test('a photo link keeps its expiry', () {
      final link =
          PhotoLink.fromJson({'accessUrl': 'https://x/y', 'expiresAt': '2026-11-08T10:00:00Z'});

      expect(link.url, 'https://x/y');
      expect(link.expiresAt, DateTime.utc(2026, 11, 8, 10));
      expect(PhotoLink.fromJson({'accessUrl': 'u'}).expiresAt, isNull);
    });
  });

  group('field projection', () {
    PreviewFields project(Map<String, dynamic> json) =>
        projectPreviewFields(ListingPreviewData.fromJson(json), _labels);

    test('mandatory fields go to Overview and every other populated field to Details', () {
      final fields = project(_json());

      expect(_asMap(fields.overview), {
        'Quantity': '1',
        'Condition notes': 'No scratches',
        'brand': 'Apple',
        'storage gb': '128 GB',
      });
      expect(_asMap(fields.details), {
        'battery health pct': '0 %',
        'has box': 'No',
        'accessories': 'Charger, Box',
        'purchase date': 'D2025-3-9',
        'age months': '6',
        'Mystery key': 'kept',
      });
      expect(fields.schemaUnavailable, isFalse);
    });

    test('a blank optional value is left out but zero and false are kept', () {
      final details = _asMap(project(_json()).details);

      expect(details.containsKey('pincode'), isFalse);
      expect(details['battery health pct'], '0 %');
      expect(details['has box'], 'No');
    });

    test('a mandatory field with no value is shown as not provided, never invented', () {
      final fields = project(_json(attributes: {'storage_gb': '64_GB'}, quantity: null));

      final missing = {
        for (final row in fields.overview)
          if (row.missing) row.label
      };
      expect(missing, {'Quantity', 'brand'});
      expect(_asMap(fields.overview)['brand'], 'Not provided');
    });

    test('the same values read the same whoever entered them', () {
      final once = project(_json());
      final again = project(_json());

      expect(_asMap(once.overview), _asMap(again.overview));
      expect(_asMap(once.details), _asMap(again.details));
    });

    test('a field required by another value is mandatory only while that value applies', () {
      Map<String, dynamic> home(Map<String, dynamic> attributes) => _json(
            attributes: attributes,
            schema: schemaJson(
              group: 'REAL_ESTATE',
              profile: 'PROP_HOME',
              common: {
                'conditionVisible': false,
                'quantityVisible': false,
                'negotiableVisible': true,
                'priceDerived': true,
              },
              intents: ['SALE', 'RENT'],
              fields: [
                field('transaction_intent', 'OPTION', required: true, options: [
                  {'code': 'SALE', 'label': 'Sale'},
                  {'code': 'RENT', 'label': 'Rent'},
                ]),
                field('sale_price', 'DECIMAL', unit: 'INR', requiredWhen: {
                  'key': 'transaction_intent',
                  'values': ['SALE'],
                }),
                field('monthly_rent', 'DECIMAL', unit: 'INR', requiredWhen: {
                  'key': 'transaction_intent',
                  'values': ['RENT'],
                }),
                field('maintenance', 'DECIMAL', unit: 'INR'),
              ],
            ),
          );

      final sale = project(home({'transaction_intent': 'SALE', 'sale_price': 5000000}));
      expect(_asMap(sale.overview), {'transaction intent': 'Sale'});
      expect(sale.details, isEmpty);

      final rent = project(home({
        'transaction_intent': 'RENT',
        'monthly_rent': 20000,
        'sale_price': 99,
        'maintenance': 1500,
      }));
      expect(_asMap(rent.overview), {'transaction intent': 'Rent'});
      expect(_asMap(rent.details), {'sale price': '₹99', 'maintenance': '₹1,500'});
    });

    test('hidden common fields are not listed', () {
      final fields = project(_json(
        schema: schemaJson(
          common: {
            'conditionVisible': false,
            'quantityVisible': false,
            'negotiableVisible': false,
            'priceDerived': false,
          },
          fields: _phoneFields,
        ),
      ));

      expect(_asMap(fields.overview).keys, {'brand', 'storage gb'});
    });

    test('without the category form nothing is called mandatory and the known values stay', () {
      final fields = project(_json(schema: null));

      expect(fields.schemaUnavailable, isTrue);
      expect(fields.overview, isEmpty);
      expect(_asMap(fields.details), {'Quantity': '1', 'Condition notes': 'No scratches'});
    });

    test('values are written in words: options, dates, lists, objects and plain text', () {
      final field = ListingSchema.fromJson(schemaJson(fields: _phoneFields)).fields;
      expect(formatPreviewValue(field[1], '64_GB', _labels), '64 GB');
      expect(formatPreviewValue(field[1], 'Unknown', _labels), 'Unknown');
      expect(formatPreviewValue(field[6], '2025-03-09', _labels), 'D2025-3-9');
      expect(formatPreviewValue(field[6], 'not a date', _labels), 'not a date');
      expect(formatPreviewValue(field[5], ['CHARGER', ''], _labels), 'Charger');
      expect(formatPreviewValue(null, {'min_size': 2, 'ok': true, 'skip': ''}, _labels),
          'Min size: 2; Ok: Yes');
      expect(formatPreviewValue(null, '<b>bold</b>', _labels), '<b>bold</b>');
      expect(formatPreviewValue(field[2], 12.5, _labels), '12.5 %');
    });
  });

  group('repository', () {
    late FakeHttpAdapter api;
    late ListingRepository repository;

    void use(FakeHandler handler) {
      api = FakeHttpAdapter(handler);
      repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
        Dio(),
      );
    }

    test('reads the preview from the owner listing endpoint and parses the extras', () async {
      use((_) async => FakeHttpAdapter.ok(_json(reviewReason: 'Add a photo')));

      final data = await repository.getListingPreview('l1');

      expect(api.requests.single.method, 'GET');
      expect(api.requests.single.path, '/listings/l1');
      expect(data.title, 'Apple Watch');
      expect(data.reviewReason, 'Add a photo');
      expect(data.schema, isNotNull);
    });

    test('a photo link comes from the media access call and keeps its expiry', () async {
      use((_) async => FakeHttpAdapter.ok(
          {'accessUrl': 'https://files/m1', 'expiresAt': '2026-11-08T10:00:00Z'}));

      final link = await repository.photoLink('m1');

      expect(api.requests.single.method, 'POST');
      expect(api.requests.single.path, '/media/m1/access');
      expect(link.url, 'https://files/m1');
      expect(link.expiresAt, DateTime.utc(2026, 11, 8, 10));
    });

    test('another seller\'s listing is refused with its code', () async {
      use((_) async => FakeHttpAdapter.error(404, 'LISTING_NOT_FOUND', 'Listing not found'));

      await expectLater(
        repository.getListingPreview('other'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'LISTING_NOT_FOUND')),
      );
    });
  });

  group('screen', () {
    late _MockRepository repository;
    late AppHarness harness;

    Future<void> open(
      WidgetTester tester, {
      Map<String, dynamic>? json,
      Object? error,
      Size size = const Size(390, 1000),
      double textScale = 1,
    }) async {
      if (error != null) {
        when(() => repository.getListingPreview('l1')).thenAnswer((_) async => throw error);
      } else {
        when(() => repository.getListingPreview('l1'))
            .thenAnswer((_) async => ListingPreviewData.fromJson(json ?? _json()));
      }
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(_FakeLocation.new),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: RouteNames.home);
      unawaited(showListingPreview(tester.element(find.byType(HomeScreen)), 'l1'));
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      await harness.settle();
    }

    setUp(() {
      repository = _MockRepository();
      when(() => repository.photoLink(any())).thenAnswer((_) async => const PhotoLink(url: ''));
      when(() => repository.categoryChildren(parentCode: null, scope: CategoryScope.popular))
          .thenAnswer((_) async => const <CategoryNode>[]);
    });

    testWidgets('shows the saved listing as buyers will see it, read-only', (tester) async {
      await open(tester);

      expect(find.byType(ListingPreviewScreen), findsOneWidget);
      expect(find.text('Listing preview'), findsOneWidget);
      expect(find.text('Electronics > Wearables > Smartwatches'), findsOneWidget);
      expect(find.text('Apple Watch'), findsOneWidget);
      expect(find.text('Like New'), findsOneWidget);
      expect(find.text('₹14,500'), findsOneWidget);
      expect(find.text('Negotiable'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);
      expect(find.text('Boosted plan'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Your listing is visible to buyers.'), findsOneWidget);
      verify(() => repository.getListingPreview('l1')).called(1);
      await harness.dispose();
    });

    testWidgets('is a popup over the current page, closed by its close button', (tester) async {
      await open(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await harness.settle();

      expect(find.byType(ListingPreviewScreen), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('has exactly the Overview and Details tabs and shows the location once',
        (tester) async {
      await open(tester);

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Location'), findsNothing);
      expect(find.text('Bengaluru'), findsOneWidget);
      await tester.tap(find.text('Details'));
      await harness.settle();
      expect(find.text('Bengaluru'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Overview lists the mandatory fields and Details the other populated ones',
        (tester) async {
      await open(tester);

      expect(find.text('About this item'), findsOneWidget);
      expect(find.text('Lightly used, with the original box.'), findsOneWidget);
      expect(find.text('Key details'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('128 GB'), findsOneWidget);
      expect(find.text('No scratches'), findsOneWidget);
      expect(find.text('battery health pct'), findsNothing);

      await tester.tap(find.text('Details'));
      await harness.settle();

      expect(find.text('Item details'), findsOneWidget);
      expect(find.text('battery health pct'), findsOneWidget);
      expect(find.text('0 %'), findsOneWidget);
      expect(find.text('Charger, Box'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      await harness.dispose();
    });

    testWidgets('an empty Details tab says so', (tester) async {
      await open(tester, json: _json(attributes: {'brand': 'Apple', 'storage_gb': '64_GB'}));

      await tester.tap(find.text('Details'));
      await harness.settle();

      expect(find.text('No additional details'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a missing mandatory value reads Not provided', (tester) async {
      await open(tester, json: _json(attributes: {'storage_gb': '64_GB'}, description: ''));

      expect(find.text('Not provided'), findsNWidgets(2));
      await harness.dispose();
    });

    testWidgets('a missing category form says details are unavailable and retries', (tester) async {
      await open(tester, json: _json(schema: null));

      expect(find.textContaining("can't be shown right now"), findsOneWidget);
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await harness.settle();
      verify(() => repository.getListingPreview('l1')).called(2);
      await harness.dispose();
    });

    testWidgets('a listing sent back shows the review reason', (tester) async {
      await open(tester,
          json: _json(
              status: 'REVISION_REQUIRED', reviewReason: 'Add a clearer photo', publishedAt: null));

      expect(find.text('Needs changes'), findsOneWidget);
      expect(find.text('Reason: Add a clearer photo'), findsOneWidget);
      expect(find.textContaining('Boosted'), findsNothing);
      await harness.dispose();
    });

    testWidgets('each state has its own banner and the plan badge waits for publication',
        (tester) async {
      const cases = {
        'DRAFT': 'Not submitted yet',
        'PLAN_PAYMENT_PENDING': 'confirming your payment',
        'TRUST_SAFETY_REVIEW': 'reviewing your listing',
        'SOLD': 'has been sold',
        'EXPIRED': 'plan has ended',
        'REJECTED': 'was not approved',
        'REMOVED_BY_ADMIN': 'not available to buyers',
        'SOMETHING_NEW': 'not available to buyers',
      };
      for (final entry in cases.entries) {
        await open(tester, json: _json(status: entry.key, publishedAt: null));

        expect(find.textContaining(entry.value), findsOneWidget, reason: entry.key);
        expect(find.text('Boosted plan'), findsNothing, reason: entry.key);
        await harness.dispose();
      }
    });

    testWidgets('buyer actions are shown and every one of them is switched off', (tester) async {
      await open(tester);

      for (final label in ['Chat', 'Call', 'Video', 'Make an Offer', 'Buy Now']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Buyer actions are unavailable in preview'), findsOneWidget);
      final secondary = tester.widgetList<SingleToneButton>(
        find.descendant(
          of: find.byType(ListingPreviewScreen),
          matching: find.byType(SingleToneButton),
        ),
      );
      expect(secondary, hasLength(4));
      expect(secondary.every((button) => button.onPressed == null), isTrue);
      await tester.tap(find.text('Chat'), warnIfMissed: false);
      await tester.tap(find.text('Buy Now'), warnIfMissed: false);
      await harness.settle();
      expect(find.byType(ListingPreviewScreen), findsOneWidget);
      verifyNever(() => repository.getListing(any()));
      await harness.dispose();
    });

    testWidgets('showing the preview changes nothing on the listing', (tester) async {
      await open(tester);

      await tester.tap(find.text('Details'));
      await harness.settle();

      verify(() => repository.getListingPreview('l1')).called(1);
      verify(() => repository.categoryChildren(parentCode: null, scope: CategoryScope.popular))
          .called(1);
      verifyNoMoreInteractions(repository);
      await harness.dispose();
    });

    testWidgets('shows each photo with a counter and loads its link only when needed',
        (tester) async {
      await open(tester,
          json: _json(images: [
            {'imageId': 'i1', 'mediaId': 'm1', 'sortOrder': 0},
            {'imageId': 'i2', 'mediaId': 'm2', 'sortOrder': 1},
          ]));

      expect(find.text('1 / 2'), findsOneWidget);
      verify(() => repository.photoLink('m1')).called(1);
      verifyNever(() => repository.photoLink('m2'));
      await harness.dispose();
    });

    testWidgets('a photo that cannot be loaded can be retried without hiding the page',
        (tester) async {
      var attempts = 0;
      when(() => repository.photoLink('m1')).thenAnswer((_) async {
        if (attempts++ == 0) throw const ApiError(type: ApiErrorType.network, message: 'offline');
        return const PhotoLink(url: '');
      });
      await open(tester,
          json: _json(images: [
            {'imageId': 'i1', 'mediaId': 'm1', 'sortOrder': 0},
          ]));

      expect(find.text('This photo could not be loaded'), findsOneWidget);
      expect(find.text('Apple Watch'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('This photo could not be loaded'), findsNothing);
      expect(attempts, 2);
      await harness.dispose();
    });

    testWidgets('a listing without photos says so', (tester) async {
      await open(tester);

      expect(find.text('No photo'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('another seller\'s or a deleted listing is not found, with a way to retry',
        (tester) async {
      await open(tester,
          error: const ApiError(
              type: ApiErrorType.business,
              message: 'Listing not found',
              code: 'LISTING_NOT_FOUND',
              statusCode: 404));

      expect(find.text('This listing is no longer available'), findsOneWidget);
      expect(find.text('Apple Watch'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a network failure offers a retry that loads the listing', (tester) async {
      var attempts = 0;
      when(() => repository.getListingPreview('l1')).thenAnswer((_) async {
        if (attempts++ == 0) throw const ApiError(type: ApiErrorType.network, message: 'offline');
        return ListingPreviewData.fromJson(_json());
      });
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(_FakeLocation.new),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: RouteNames.home);
      unawaited(showListingPreview(tester.element(find.byType(HomeScreen)), 'l1'));
      await harness.settle();

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Apple Watch'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('shows the page in Hindi', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('hi')];
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await open(tester);

      expect(find.text('लिस्टिंग पूर्वावलोकन'), findsOneWidget);
      expect(find.text('ओवरव्यू'), findsOneWidget);
      expect(find.text('विवरण'), findsOneWidget);
      expect(find.text('आपकी लिस्टिंग खरीदारों को दिख रही है।'), findsOneWidget);
      expect(find.text('अभी खरीदें'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('meets the tap target, label and contrast guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      semantics.dispose();
      await harness.dispose();
    });

    for (final language in ['en', 'hi']) {
      testWidgets('scrolls without overflow on a narrow phone at 2x text size in $language',
          (tester) async {
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await open(tester,
            textScale: 2,
            size: const Size(320, 640),
            json: _json(images: [
              {'imageId': 'i1', 'mediaId': 'm1', 'sortOrder': 0},
            ]));

        expect(tester.takeException(), isNull);
        final details = find.text(language == 'en' ? 'Details' : 'विवरण');
        await tester.ensureVisible(details);
        await tester.tap(details);
        await harness.settle();
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });
}
