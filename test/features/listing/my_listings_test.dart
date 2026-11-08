import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing/domain/existing_listing.dart';
import 'package:valuex_mobile/features/listing/domain/listing_preview.dart';
import 'package:valuex_mobile/features/listing/domain/my_listings.dart';
import 'package:valuex_mobile/features/listing/presentation/item_details_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_plan_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_preview_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/my_listings_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/my_listings_controller.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/listing_status_badge.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/option_chip.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';
import 'package:valuex_mobile/features/settings/presentation/providers/locale_controller.dart';

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

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

Map<String, dynamic> _item(
  String id, {
  String title = 'Hero cycle',
  String status = 'PUBLISHED',
  num? price = 4500,
  String? planName = 'Basic',
  bool canEdit = true,
  bool canDelete = true,
}) =>
    {
      'id': id,
      'title': title,
      'price': price,
      'status': status,
      'planName': planName,
      'viewCount': 0,
      'chatCount': 0,
      'thumbnailUrl': null,
      'canEdit': canEdit,
      'canDelete': canDelete,
    };

Map<String, dynamic> _pageJson(
  List<Map<String, dynamic>> items, {
  int total = 3,
  int active = 1,
  int sold = 1,
  int page = 0,
  bool hasNext = false,
}) =>
    {
      'summary': {'total': total, 'active': active, 'sold': sold, 'totalViews': 0},
      'items': items,
      'page': page,
      'hasNext': hasNext,
    };

MyListingsPage _page(
  List<Map<String, dynamic>> items, {
  int total = 3,
  int active = 1,
  int sold = 1,
  int page = 0,
  bool hasNext = false,
}) =>
    MyListingsPage.fromJson(
        _pageJson(items, total: total, active: active, sold: sold, page: page, hasNext: hasNext));

final _live = _item('l1');
final _sold =
    _item('l2', title: 'Sold bike', status: 'SOLD', price: 800, canEdit: false, canDelete: false);
final _review = _item('l3',
    title: 'Under review chair',
    status: 'TRUST_SAFETY_REVIEW',
    price: 1200,
    canEdit: false,
    canDelete: false);
final _all = [_live, _sold, _review];

ExistingListing _existing(String status) => ExistingListing(
      listingId: 'l1',
      status: status,
      draft: complete,
      category: const CategoryRef(
        code: 'CAT-1',
        name: 'Android Phones',
        path: [
          CategoryPathItem(code: 'L1-M', name: 'Mobiles & Tablets', level: 1),
          CategoryPathItem(code: 'L2-S', name: 'Smartphones', level: 2),
          CategoryPathItem(code: 'CAT-1', name: 'Android Phones', level: 3),
        ],
      ),
      city: 'Pune',
      images: const [
        ListingImageRef(imageId: 'i1', mediaId: 'm1', sortOrder: 0),
        ListingImageRef(imageId: 'i2', mediaId: 'm2', sortOrder: 1),
      ],
    );

void main() {
  setUpAll(() {
    registerFallbackValue(MyListingsFilter.all);
    loadBrandFonts();
  });

  group('models', () {
    test('a page reads its counts and listings', () {
      final page =
          MyListingsPage.fromJson(_pageJson(_all, total: 3, active: 1, sold: 1, hasNext: true));

      expect(page.summary.total, 3);
      expect(page.summary.active, 1);
      expect(page.summary.sold, 1);
      expect(page.summary.totalViews, 0);
      expect(page.hasNext, isTrue);
      expect(page.items.map((item) => item.id), ['l1', 'l2', 'l3']);
      final live = page.items.first;
      expect(live.title, 'Hero cycle');
      expect(live.price, 4500);
      expect(live.planName, 'Basic');
      expect(live.canEdit && live.canDelete, isTrue);
      expect(page.items[1].isSold, isTrue);
    });

    test('missing fields read as empty, zero and not allowed', () {
      final page = MyListingsPage.fromJson({
        'items': [
          {'id': 'x', 'status': 'DRAFT'}
        ],
      });

      expect(page.summary.total, 0);
      expect(page.items.single.title, '');
      expect(page.items.single.price, isNull);
      expect(page.items.single.canEdit, isFalse);
      expect(page.items.single.canDelete, isFalse);
      expect(page.hasNext, isFalse);
    });

    test('every server status reads as one of the badges', () {
      const expected = {
        'PUBLISHED': ListingBadge.active,
        'SOLD': ListingBadge.sold,
        'DRAFT': ListingBadge.draft,
        'PLAN_SELECTION_PENDING': ListingBadge.draft,
        'PLAN_PAYMENT_FAILED': ListingBadge.draft,
        'PLAN_PAYMENT_PENDING': ListingBadge.processingPayment,
        'PLAN_PAYMENT_SUCCESS': ListingBadge.processingPayment,
        'TRUST_SAFETY_REVIEW': ListingBadge.underReview,
        'APPROVED': ListingBadge.underReview,
        'REVISION_REQUIRED': ListingBadge.needsChanges,
        'EXPIRED': ListingBadge.expired,
        'REJECTED': ListingBadge.rejected,
        'REMOVED_BY_ADMIN': ListingBadge.unavailable,
        '': ListingBadge.unavailable,
      };
      expected.forEach((status, badge) {
        expect(ListingBadge.forStatus(status), badge, reason: status);
      });
    });

    test('the filters send ACTIVE and SOLD, and All sends nothing', () {
      expect(MyListingsFilter.all.apiValue, isNull);
      expect(MyListingsFilter.active.apiValue, 'ACTIVE');
      expect(MyListingsFilter.sold.apiValue, 'SOLD');
    });

    test('an existing listing keeps its photos for the edit page', () {
      final listing = ExistingListing.fromJson({
        'listingId': 'l1',
        'status': 'PUBLISHED',
        'images': [
          {'imageId': 'i2', 'mediaId': 'm2', 'sortOrder': 1},
          {'imageId': 'i1', 'mediaId': 'm1', 'sortOrder': 0},
        ],
      });

      expect(listing.images.map((image) => image.imageId), ['i2', 'i1']);
      expect(listing.images.last.mediaId, 'm1');
      expect(ExistingListing.fromJson({'listingId': 'l1', 'status': 'DRAFT'}).images, isEmpty);
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

    test('asks for a page of the chosen filter and parses it', () async {
      use((_) async => FakeHttpAdapter.ok(_pageJson(_all, hasNext: true)));

      final page = await repository.myListings(filter: MyListingsFilter.active, page: 2, size: 10);

      final request = api.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/listings/mine');
      expect(request.queryParameters, {'page': 2, 'size': 10, 'status': 'ACTIVE'});
      expect(page.items, hasLength(3));
      expect(page.hasNext, isTrue);
    });

    test('All leaves the status out', () async {
      use((_) async => FakeHttpAdapter.ok(_pageJson([])));

      await repository.myListings();

      expect(api.requests.single.queryParameters, {'page': 0, 'size': 20});
    });

    test('deleting answers 204 with no body and succeeds', () async {
      use((_) async => ResponseBody.fromString('', 204));

      await repository.deleteListing('l1');

      expect(api.requests.single.method, 'DELETE');
      expect(api.requests.single.path, '/listings/l1');
    });

    test('a refused delete is thrown with its code', () async {
      use((_) async => FakeHttpAdapter.error(400, 'ERROR_LISTING_NOT_DELETABLE', 'no'));

      await expectLater(
        repository.deleteListing('l1'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_LISTING_NOT_DELETABLE')),
      );
    });

    test('a photo link comes from the media access call', () async {
      use((_) async => FakeHttpAdapter.ok({'accessUrl': 'https://cdn/m1', 'expiresAt': 'x'}));

      expect(await repository.photoUrl('m1'), 'https://cdn/m1');
      expect(api.requests.single.method, 'POST');
      expect(api.requests.single.path, '/media/m1/access');
    });

    test('an edit of a live listing sends the details with the photo changes', () async {
      use((_) async => FakeHttpAdapter.ok(null));

      await repository.editLiveListing(
        'l1',
        complete,
        phoneSchema,
        city: 'Pune',
        addMediaIds: ['m9'],
        removeImageIds: ['i2'],
      );

      final request = api.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/listings/l1');
      expect(request.queryParameters, isEmpty);
      final body = request.data as Map<String, dynamic>;
      expect(body['title'], 'Sony headphones');
      expect(body['location'], 'Pune');
      expect(body['addMediaIds'], ['m9']);
      expect(body['removeImageIds'], ['i2']);
    });

    test('the confirmation is sent as a query parameter, and photo lists are left out when empty',
        () async {
      use((_) async => FakeHttpAdapter.ok(null));

      await repository.editLiveListing('l1', complete, phoneSchema, confirmRemoderation: true);

      final request = api.requests.single;
      expect(request.queryParameters, {'confirmRemoderation': true});
      final body = request.data as Map<String, dynamic>;
      expect(body.containsKey('addMediaIds'), isFalse);
      expect(body.containsKey('removeImageIds'), isFalse);
    });

    test('a major edit comes back as a 409 with its reasons', () async {
      use((_) async => FakeHttpAdapter.error(
            409,
            'ERROR_REMODERATION_CONFIRMATION_REQUIRED',
            'review',
            details: {'reasons': 'PRICE_CHANGE_TOO_HIGH,PHOTOS_ADDED'},
          ));

      await expectLater(
        repository.editLiveListing('l1', complete, phoneSchema),
        throwsA(isA<ApiError>()
            .having((e) => e.statusCode, 'status', 409)
            .having((e) => e.code, 'code', 'ERROR_REMODERATION_CONFIRMATION_REQUIRED')
            .having((e) => e.details['reasons'], 'reasons', 'PRICE_CHANGE_TOO_HIGH,PHOTOS_ADDED')),
      );
    });
  });

  group('controller', () {
    late _MockRepository repository;
    late ProviderContainer container;

    MyListingsController controller() => container.read(myListingsControllerProvider.notifier);
    MyListingsState state() => container.read(myListingsControllerProvider);

    void stubPages(Map<MyListingsFilter, List<MyListingsPage>> pages) {
      final served = <MyListingsFilter, int>{};
      when(() => repository.myListings(
            filter: any(named: 'filter'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((invocation) async {
        final filter = invocation.namedArguments[#filter] as MyListingsFilter;
        final page = invocation.namedArguments[#page] as int;
        served[filter] = (served[filter] ?? 0) + 1;
        return pages[filter]![page];
      });
    }

    setUp(() {
      repository = _MockRepository();
      container =
          ProviderContainer(overrides: [listingRepositoryProvider.overrideWithValue(repository)]);
      addTearDown(container.dispose);
    });

    test('loads the first page of All', () async {
      stubPages({
        MyListingsFilter.all: [_page(_all)]
      });

      await controller().load();

      expect(state().isLoading, isFalse);
      expect(state().items.map((item) => item.id), ['l1', 'l2', 'l3']);
      expect(state().summary.total, 3);
      expect(state().error, isNull);
      expect(state().hasNext, isFalse);
    });

    test('a failed first load keeps the error and Retry loads again', () async {
      when(() => repository.myListings(
            filter: any(named: 'filter'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenThrow(_offline);

      await controller().load();

      expect(state().error, _offline);
      expect(state().items, isEmpty);
      expect(state().isLoading, isFalse);
      stubPages({
        MyListingsFilter.all: [_page(_all)]
      });

      await controller().load();

      expect(state().error, isNull);
      expect(state().items, hasLength(3));
    });

    test('choosing a filter clears the list and loads that filter', () async {
      stubPages({
        MyListingsFilter.all: [_page(_all)],
        MyListingsFilter.sold: [
          _page([_sold])
        ],
      });
      await controller().load();

      final loading = controller().load(filter: MyListingsFilter.sold);

      expect(state().filter, MyListingsFilter.sold);
      expect(state().items, isEmpty);
      expect(state().isLoading, isTrue);
      await loading;
      expect(state().items.map((item) => item.id), ['l2']);
    });

    test('refreshing keeps what is shown until the new page arrives', () async {
      stubPages({
        MyListingsFilter.all: [_page(_all)]
      });
      await controller().load();

      final refreshing = controller().load();

      expect(state().items, hasLength(3));
      expect(state().isLoading, isTrue);
      await refreshing;
    });

    test('loads the next page below the first and stops when there is none', () async {
      stubPages({
        MyListingsFilter.all: [
          _page([_live], hasNext: true),
          _page([_sold], page: 1),
        ],
      });
      await controller().load();
      expect(state().hasNext, isTrue);

      expect(await controller().loadMore(), isNull);

      expect(state().items.map((item) => item.id), ['l1', 'l2']);
      expect(state().hasNext, isFalse);
      expect(await controller().loadMore(), isNull);
      verify(() => repository.myListings(
          filter: MyListingsFilter.all, page: 1, size: MyListingsController.pageSize)).called(1);
    });

    test('a failed next page keeps the list and returns the error', () async {
      final calls = <int>[];
      when(() => repository.myListings(
            filter: any(named: 'filter'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int;
        calls.add(page);
        if (page == 0) return _page([_live], hasNext: true);
        throw _offline;
      });
      await controller().load();

      expect(await controller().loadMore(), _offline);

      expect(state().items, hasLength(1));
      expect(state().isLoadingMore, isFalse);
      expect(state().hasNext, isTrue);
    });

    test('a listing is hidden while the delete can be undone and back after Undo', () async {
      stubPages({
        MyListingsFilter.all: [_page(_all)]
      });
      await controller().load();

      controller().hide('l1');
      expect(state().visibleItems.map((item) => item.id), ['l2', 'l3']);
      expect(state().items, hasLength(3));

      controller().restore('l1');
      expect(state().visibleItems, hasLength(3));
      verifyNever(() => repository.deleteListing(any()));
    });

    test('a committed delete removes the listing and lowers the counts', () async {
      stubPages({
        MyListingsFilter.all: [_page(_all)]
      });
      when(() => repository.deleteListing('l1')).thenAnswer((_) async {});
      await controller().load();
      controller().hide('l1');

      expect(await controller().commitDelete('l1'), isNull);

      expect(state().items.map((item) => item.id), ['l2', 'l3']);
      expect(state().pendingDeletes, isEmpty);
      expect(state().summary.total, 2);
      expect(state().summary.active, 0);
      expect(state().summary.sold, 1);
    });

    test('deleting a listing that is not published leaves Active alone', () async {
      stubPages({
        MyListingsFilter.all: [_page(_all)]
      });
      when(() => repository.deleteListing('l3')).thenAnswer((_) async {});
      await controller().load();

      await controller().commitDelete('l3');

      expect(state().summary.total, 2);
      expect(state().summary.active, 1);
    });

    test('a refused delete brings the listing back and returns the error', () async {
      stubPages({
        MyListingsFilter.all: [_page(_all)]
      });
      const refused =
          ApiError(type: ApiErrorType.business, message: 'no', code: 'ERROR_LISTING_NOT_DELETABLE');
      when(() => repository.deleteListing('l1')).thenThrow(refused);
      await controller().load();
      controller().hide('l1');

      expect(await controller().commitDelete('l1'), refused);

      expect(state().visibleItems, hasLength(3));
      expect(state().summary.total, 3);
    });
  });

  group('screen', () {
    late _MockRepository repository;
    late AppHarness harness;

    void stubList({
      List<Map<String, dynamic>>? items,
      Map<MyListingsFilter, MyListingsPage>? byFilter,
      Object? error,
    }) {
      when(() => repository.myListings(
            filter: any(named: 'filter'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((invocation) async {
        if (error != null) throw error;
        final filter = invocation.namedArguments[#filter] as MyListingsFilter;
        if (byFilter != null) return byFilter[filter] ?? _page([]);
        return _page(items ?? _all);
      });
    }

    void stubPreview(String id, String status) {
      when(() => repository.getListingPreview(id)).thenAnswer(
          (_) async => ListingPreviewData(listingId: id, status: status, title: 'Thing'));
    }

    Future<void> launch(
      WidgetTester tester, {
      List<Map<String, dynamic>>? items,
      Map<MyListingsFilter, MyListingsPage>? byFilter,
      Object? error,
      String location = RouteNames.myListings,
      bool signedIn = true,
    }) async {
      stubList(items: items, byFilter: byFilter, error: error);
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(_FakeLocation.new),
      ]);
      if (signedIn) harness.signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: location);
      await harness.settle();
    }

    setUp(() {
      repository = _MockRepository();
      when(() => repository.listingSchema(any())).thenAnswer((_) async => phoneSchema);
      when(() => repository.photoUrl(any())).thenAnswer((_) async => '');
      when(() => repository.sellerPlans()).thenAnswer((_) async => []);
    });

    testWidgets('shows the counts, the filters and a card for every listing', (tester) async {
      await launch(tester);

      expect(find.byType(MyListingsScreen), findsOneWidget);
      expect(find.text('My Listings'), findsOneWidget);
      expect(find.text('3 total listings'), findsOneWidget);
      expect(find.text('Total Views'), findsOneWidget);
      expect(find.widgetWithText(OptionChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(OptionChip, 'Active'), findsOneWidget);
      expect(find.widgetWithText(OptionChip, 'Sold'), findsOneWidget);
      expect(find.text('Hero cycle'), findsOneWidget);
      expect(find.text('₹4,500'), findsOneWidget);
      expect(find.text('Basic plan'), findsNWidgets(3));
      expect(find.byType(ListingStatusBadge), findsNWidgets(3));
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('0 views'), findsNWidgets(3));
      expect(find.text('0 chats'), findsNWidgets(3));
      await harness.dispose();
    });

    testWidgets('a summary card is read as one phrase', (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester);

      expect(find.bySemanticsLabel('1 Active'), findsOneWidget);
      expect(find.bySemanticsLabel('1 Sold'), findsOneWidget);
      expect(find.bySemanticsLabel('0 Total Views'), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('the edit icon and the delete button show only where the server allows them',
        (tester) async {
      await launch(tester);

      expect(find.byTooltip('Edit Hero cycle'), findsOneWidget);
      expect(find.byTooltip('Delete Hero cycle'), findsOneWidget);
      expect(find.byTooltip('Edit Sold bike'), findsNothing);
      expect(find.byTooltip('Delete Sold bike'), findsNothing);
      expect(find.byTooltip('Edit Under review chair'), findsNothing);
      expect(find.byTooltip('Delete Under review chair'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a draft without a title shows "Untitled listing" and no price', (tester) async {
      await launch(tester, items: [
        _item('d1', title: '', status: 'DRAFT', price: null, planName: null),
      ]);

      expect(find.text('Untitled listing'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.textContaining('plan'), findsNothing);
      expect(find.textContaining('₹'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a listing with no photo shows the placeholder instead of failing', (tester) async {
      await launch(tester);

      expect(find.byIcon(Icons.image_outlined), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await harness.dispose();
    });

    testWidgets('choosing Active or Sold asks the server for that filter', (tester) async {
      await launch(tester, byFilter: {
        MyListingsFilter.all: _page(_all),
        MyListingsFilter.active: _page([_live]),
        MyListingsFilter.sold: _page([_sold]),
      });

      await tester.tap(find.widgetWithText(OptionChip, 'Active'));
      await harness.settle();
      expect(find.text('Hero cycle'), findsOneWidget);
      expect(find.text('Sold bike'), findsNothing);

      await tester.tap(find.widgetWithText(OptionChip, 'Sold'));
      await harness.settle();
      expect(find.text('Sold bike'), findsOneWidget);
      expect(find.text('Hero cycle'), findsNothing);

      await tester.tap(find.widgetWithText(OptionChip, 'All'));
      await harness.settle();
      expect(find.text('Under review chair'), findsOneWidget);
      verify(() => repository.myListings(
          filter: MyListingsFilter.active, page: 0, size: MyListingsController.pageSize)).called(1);
      await harness.dispose();
    });

    testWidgets('each filter says so when it has nothing, and All offers to list an item',
        (tester) async {
      await launch(tester, byFilter: {
        MyListingsFilter.all: _page([], total: 0, active: 0, sold: 0),
      });

      expect(find.text("You haven't listed anything yet"), findsOneWidget);
      expect(find.text('List an item'), findsOneWidget);
      expect(find.text('0 total listings'), findsOneWidget);

      await tester.tap(find.widgetWithText(OptionChip, 'Active'));
      await harness.settle();
      expect(find.text('You have no active listings'), findsOneWidget);
      expect(find.text('List an item'), findsNothing);

      await tester.tap(find.widgetWithText(OptionChip, 'Sold'));
      await harness.settle();
      expect(find.text("You haven't sold anything yet"), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failed load shows the error, and Retry loads again', (tester) async {
      await launch(tester, error: _offline);

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Hero cycle'), findsNothing);
      stubList();

      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Hero cycle'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Load more adds the next page below the first', (tester) async {
      var calls = 0;
      when(() => repository.myListings(
            filter: any(named: 'filter'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((invocation) async {
        calls++;
        final page = invocation.namedArguments[#page] as int;
        return page == 0 ? _page([_live], hasNext: true) : _page([_sold], page: 1);
      });
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: RouteNames.myListings);
      await harness.settle();

      await tester.scrollUntilVisible(find.text('Load more'), 200);
      await tester.tap(find.text('Load more'));
      await harness.settle();

      expect(find.text('Sold bike'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
      expect(calls, 2);
      await harness.dispose();
    });

    testWidgets('tapping a live listing opens it for editing with its stored details',
        (tester) async {
      when(() => repository.getListing('l1')).thenAnswer((_) async => _existing('PUBLISHED'));
      await launch(tester);

      await tester.tap(find.text('Hero cycle'));
      await harness.settle();

      verify(() => repository.getListing('l1')).called(1);
      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text('Edit Listing'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the edit icon opens the same page as the card', (tester) async {
      when(() => repository.getListing('l1')).thenAnswer((_) async => _existing('PUBLISHED'));
      await launch(tester);

      await tester.tap(find.byTooltip('Edit Hero cycle'));
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a draft opens Item Details to carry on', (tester) async {
      when(() => repository.getListing('d1')).thenAnswer((_) async => _existing('DRAFT'));
      await launch(tester, items: [_item('d1', title: 'My draft', status: 'DRAFT')]);

      await tester.tap(find.text('My draft'));
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text('Item Details'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a listing whose payment failed opens plan selection', (tester) async {
      when(() => repository.getListing('p1'))
          .thenAnswer((_) async => _existing('PLAN_PAYMENT_FAILED'));
      await launch(tester, items: [
        _item('p1', title: 'Pay again', status: 'PLAN_PAYMENT_FAILED', canEdit: false),
      ]);

      await tester.tap(find.text('Pay again'));
      await harness.settle();

      expect(find.byType(ListingPlanScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a listing in review opens its preview instead of the editor', (tester) async {
      stubPreview('l3', 'TRUST_SAFETY_REVIEW');
      await launch(tester);

      await tester.tap(find.text('Under review chair'));
      await harness.settle();

      expect(find.byType(ListingPreviewScreen), findsOneWidget);
      expect(find.textContaining('reviewing your listing'), findsOneWidget);
      verify(() => repository.getListingPreview('l3')).called(1);
      verifyNever(() => repository.getListing(any()));
      await harness.dispose();
    });

    testWidgets('each status that cannot be opened for editing shows its own preview banner',
        (tester) async {
      const cases = {
        'PLAN_PAYMENT_PENDING': 'confirming your payment',
        'EXPIRED': 'plan has ended',
        'REJECTED': 'was not approved',
        'REMOVED_BY_ADMIN': 'not available to buyers',
      };
      for (final entry in cases.entries) {
        stubPreview('x', entry.key);
        await launch(tester, items: [
          _item('x', title: 'Thing', status: entry.key, canEdit: false, canDelete: false),
        ]);

        await tester.tap(find.text('Thing'));
        await harness.settle();

        expect(find.byType(ListingPreviewScreen), findsOneWidget, reason: entry.key);
        expect(find.textContaining(entry.value), findsOneWidget, reason: entry.key);
        await harness.dispose();
      }
    });

    testWidgets('every card has its own Preview action that leaves Edit and the card tap alone',
        (tester) async {
      stubPreview('l1', 'PUBLISHED');
      when(() => repository.getListing('l1')).thenAnswer((_) async => _existing('PUBLISHED'));
      await launch(tester);

      expect(find.text('Preview'), findsNWidgets(3));
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Preview Hero cycle'));
      await harness.settle();

      expect(find.byType(ListingPreviewScreen), findsOneWidget);
      verify(() => repository.getListingPreview('l1')).called(1);
      verifyNever(() => repository.getListing(any()));
      await harness.dispose();
    });

    testWidgets('a sold listing previews its item content but its card tap stays the sale details',
        (tester) async {
      stubPreview('l2', 'SOLD');
      await launch(tester);

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Preview Sold bike'));
      await harness.settle();

      expect(find.byType(ListingPreviewScreen), findsOneWidget);
      expect(find.text('This item has been sold.'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a sold listing says its sale details are coming soon', (tester) async {
      await launch(tester);

      await tester.tap(find.text('Sold bike'));
      await harness.settle();

      expect(find.text('Sale details are coming soon'), findsOneWidget);
      verifyNever(() => repository.getListing(any()));
      await harness.dispose();
    });

    testWidgets('a listing that is gone says why instead of opening', (tester) async {
      when(() => repository.getListing('l1')).thenThrow(const ApiError(
          type: ApiErrorType.business, message: 'x', code: 'LISTING_NOT_FOUND', statusCode: 404));
      await launch(tester);

      await tester.tap(find.text('Hero cycle'));
      await harness.settle();

      expect(find.byType(MyListingsScreen), findsOneWidget);
      expect(find.byType(ItemDetailsScreen), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      await harness.dispose();
    });

    group('delete', () {
      setUp(() {
        when(() => repository.deleteListing(any())).thenAnswer((_) async {});
      });

      Future<void> askToDelete(WidgetTester tester) async {
        await tester.tap(find.byTooltip('Delete Hero cycle'));
        await harness.settle();
      }

      Future<void> waitOutUndo(WidgetTester tester) async {
        await tester.pump(MyListingsScreen.undoWindow);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      testWidgets('asks first and says the plan fee is not refunded', (tester) async {
        await launch(tester);

        await askToDelete(tester);

        expect(find.text('Delete this listing?'), findsOneWidget);
        expect(find.textContaining('plan fee is not refunded'), findsOneWidget);
        expect(find.textContaining('Hero cycle'), findsWidgets);
        await harness.dispose();
      });

      testWidgets('Cancel keeps the listing and sends nothing', (tester) async {
        await launch(tester);
        await askToDelete(tester);

        await tester.tap(find.text('Cancel'));
        await harness.settle();

        expect(find.text('Hero cycle'), findsOneWidget);
        expect(find.text('Listing deleted'), findsNothing);
        verifyNever(() => repository.deleteListing(any()));
        await harness.dispose();
      });

      testWidgets('confirming hides the listing at once and offers Undo', (tester) async {
        await launch(tester);
        await askToDelete(tester);

        await tester.tap(find.text('Delete'));
        await harness.settle();

        expect(find.text('Hero cycle'), findsNothing);
        expect(find.text('Listing deleted'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        verifyNever(() => repository.deleteListing(any()));
        await waitOutUndo(tester);
        await harness.dispose();
      });

      testWidgets('Undo brings the listing back and nothing reaches the server', (tester) async {
        await launch(tester);
        await askToDelete(tester);
        await tester.tap(find.text('Delete'));
        await harness.settle();

        await tester.tap(find.text('Undo'));
        await waitOutUndo(tester);
        await harness.settle();

        expect(find.text('Hero cycle'), findsOneWidget);
        verifyNever(() => repository.deleteListing(any()));
        expect(find.text('3 total listings'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('the delete is sent when the undo window closes, and the counts drop',
          (tester) async {
        await launch(tester);
        await askToDelete(tester);
        await tester.tap(find.text('Delete'));
        await harness.settle();
        verifyNever(() => repository.deleteListing(any()));

        await waitOutUndo(tester);
        await harness.settle();

        verify(() => repository.deleteListing('l1')).called(1);
        expect(find.text('Hero cycle'), findsNothing);
        expect(find.text('2 total listings'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('a delete the server refuses brings the listing back with the reason',
          (tester) async {
        when(() => repository.deleteListing(any())).thenThrow(const ApiError(
            type: ApiErrorType.business, message: 'no', code: 'ERROR_LISTING_NOT_DELETABLE'));
        await launch(tester);
        await askToDelete(tester);
        await tester.tap(find.text('Delete'));
        await harness.settle();

        await waitOutUndo(tester);
        await harness.settle();

        expect(find.text('Hero cycle'), findsOneWidget);
        expect(find.textContaining("can't be deleted right now"), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('the delete still goes out when the seller leaves before the window closes',
          (tester) async {
        await launch(tester);
        await askToDelete(tester);
        await tester.tap(find.text('Delete'));
        await harness.settle();

        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pump(const Duration(milliseconds: 400));
        await waitOutUndo(tester);
        await harness.settle();

        verify(() => repository.deleteListing('l1')).called(1);
        await harness.dispose();
      });
    });

    testWidgets('the Profile menu opens My Listings', (tester) async {
      await launch(tester, location: RouteNames.profile);

      await tester.scrollUntilVisible(find.text('My Listings'), 200);
      await tester.tap(find.text('My Listings'));
      await harness.settle();

      expect(find.byType(MyListingsScreen), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();
      expect(find.byType(MyListingsScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('a signed-out visitor is sent to Sign In', (tester) async {
      await launch(tester, signedIn: false);

      expect(find.byType(MyListingsScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('the title is a heading, and the page passes the tap target and label guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester);

      expect(tester.getSemantics(find.text('My Listings').first), isSemantics(isHeader: true));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('on a 320 x 640 screen at 200% text in ${locale.languageCode} nothing overflows',
          (tester) async {
        await launch(tester);
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        tester.platformDispatcher.localeTestValue = locale;
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        await harness.settle();

        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
        await harness.settle();
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }

    testWidgets('the words come from the language in use', (tester) async {
      await launch(tester);
      await harness.container.read(localeControllerProvider.notifier).select(const Locale('hi'));
      await harness.settle();

      expect(find.text(AppLocalizationsHi().myListingsTitle), findsOneWidget);
      expect(find.text(AppLocalizationsHi().myListingsTotal(3)), findsOneWidget);
      expect(find.text('My Listings'), findsNothing);
      expect(AppLocalizationsEn().myListingsTitle, 'My Listings');
      await harness.dispose();
    });
  });
}
