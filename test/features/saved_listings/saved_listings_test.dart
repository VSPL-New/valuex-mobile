import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/constants/api_constants.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/saved_listings/data/saved_listings_repository.dart';
import 'package:valuex_mobile/features/saved_listings/domain/saved_listing.dart';
import 'package:valuex_mobile/features/saved_listings/presentation/providers/saved_hearts_controller.dart';
import 'package:valuex_mobile/features/saved_listings/presentation/providers/saved_items_controller.dart';

import 'saved_listings_fixtures.dart';

class _FakeApi extends Fake implements ApiClient {
  String? method;
  String? path;
  Map<String, dynamic>? query;
  Object? response;
  ApiError? error;

  @override
  Future<T> put<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    method = 'PUT';
    this.path = path;
    if (error != null) throw error!;
    return null as T;
  }

  @override
  Future<T> delete<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    method = 'DELETE';
    this.path = path;
    return null as T;
  }

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    method = 'GET';
    this.path = path;
    query = queryParameters;
    return parse!(response);
  }
}

ApiError _coded(String code, {Map<String, String> details = const {}}) => ApiError(
      type: ApiErrorType.business,
      message: 'x',
      code: code,
      statusCode: 409,
      details: details,
    );

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

void main() {
  group('SavedListing.fromJson', () {
    test('reads an available listing with its photo and no reason', () {
      final item = SavedListing.fromJson(savedListingJson('l1'));

      expect(item.id, 'l1');
      expect(item.title, 'Apple iPhone 14');
      expect(item.price, 42000);
      expect(item.condition, 'LIKE_NEW');
      expect(item.thumbnailUrl, 'https://media.example/thumb.jpg');
      expect(item.available, isTrue);
      expect(item.reason, isNull);
      expect(item.savedAt, DateTime.utc(2026, 11, 14, 10));
    });

    test('reads an unavailable listing with its reason and no photo', () {
      final item = SavedListing.fromJson(
        savedListingJson('l2', available: false, reason: 'SELLER_SUSPENDED'),
      );

      expect(item.available, isFalse);
      expect(item.reason, UnavailableReason.sellerSuspended);
      expect(item.thumbnailUrl, isNull);
    });

    test('tolerates missing optional fields and an unknown reason', () {
      final item = SavedListing.fromJson(const {
        'listingId': 'l3',
        'available': false,
        'unavailableReason': 'SOMETHING_NEW',
      });

      expect(item.title, '');
      expect(item.price, isNull);
      expect(item.reason, isNull);
      expect(item.savedAt, isNull);
    });

    test('maps every reason code', () {
      expect(UnavailableReason.fromApi('SOLD'), UnavailableReason.sold);
      expect(UnavailableReason.fromApi('EXPIRED'), UnavailableReason.expired);
      expect(UnavailableReason.fromApi('REMOVED'), UnavailableReason.removed);
      expect(UnavailableReason.fromApi('DELETED'), UnavailableReason.deleted);
      expect(UnavailableReason.fromApi('UNDER_REVIEW'), UnavailableReason.underReview);
      expect(UnavailableReason.fromApi(null), isNull);
    });
  });

  group('SavedListingsPage.fromJson', () {
    test('reads the paging fields and the limit', () {
      final page = savedPage([savedListingJson('a')], page: 2, hasNext: true, total: 45);

      expect(page.items, hasLength(1));
      expect(page.page, 2);
      expect(page.hasNext, isTrue);
      expect(page.totalItems, 45);
      expect(page.maxSaved, 200);
    });

    test('has safe defaults for an empty answer', () {
      final page = SavedListingsPage.fromJson(const {});

      expect(page.items, isEmpty);
      expect(page.page, 0);
      expect(page.hasNext, isFalse);
      expect(page.maxSaved, isNull);
    });
  });

  group('SavedListingsRepository', () {
    late _FakeApi api;
    late SavedListingsRepository repository;

    setUp(() {
      api = _FakeApi();
      repository = SavedListingsRepository(api);
    });

    test('saves with a PUT to the listing', () async {
      await repository.save('l1');

      expect(api.method, 'PUT');
      expect(api.path, ApiConstants.savedListing('l1'));
    });

    test('turns the limit refusal into SavedListingLimitReached with the number', () async {
      api.error = _coded('ERROR_MAX_SAVED', details: {'max': '200'});

      await expectLater(
        repository.save('l1'),
        throwsA(isA<SavedListingLimitReached>().having((e) => e.max, 'max', 200)),
      );
    });

    test('turns the unavailable refusal into SavedListingUnavailable', () async {
      api.error = _coded('ERROR_ITEM_UNAVAILABLE');

      await expectLater(repository.save('l1'), throwsA(isA<SavedListingUnavailable>()));
    });

    test('lets any other error through unchanged', () async {
      api.error = _offline;

      await expectLater(repository.save('l1'), throwsA(same(_offline)));
    });

    test('removes with a DELETE', () async {
      await repository.remove('l1');

      expect(api.method, 'DELETE');
      expect(api.path, ApiConstants.savedListing('l1'));
    });

    test('lists a page with the page size', () async {
      api.response = savedPageJson([savedListingJson('a')], page: 1);

      final page = await repository.list(page: 1);

      expect(api.path, ApiConstants.savedListings);
      expect(api.query, {'page': 1, 'size': SavedListingsRepository.pageSize});
      expect(page.items.single.id, 'a');
    });
  });

  group('SavedHeartsController', () {
    late FakeSavedListingsRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeSavedListingsRepository();
      container = ProviderContainer(
        overrides: [savedListingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
    });

    Map<String, bool> hearts() => container.read(savedHeartsProvider);

    test('saves, shows the heart at once and reports it', () async {
      final pending = Completer<void>();
      repository.onSave = (id) => pending.future;

      final future =
          container.read(savedHeartsProvider.notifier).toggle('l1', currentlySaved: false);

      expect(hearts()['l1'], isTrue, reason: 'optimistic');
      pending.complete();
      final outcome = await future;
      expect(outcome!.status, SaveHeartStatus.saved);
      expect(outcome.failed, isFalse);
      expect(repository.saved, ['l1']);
      expect(hearts()['l1'], isTrue);
    });

    test('removes a saved listing', () async {
      final outcome =
          await container.read(savedHeartsProvider.notifier).toggle('l1', currentlySaved: true);

      expect(outcome!.status, SaveHeartStatus.removed);
      expect(repository.removed, ['l1']);
      expect(hearts()['l1'], isFalse);
    });

    test('puts the heart back when the server fails', () async {
      repository.onSave = (id) async => throw _offline;

      final outcome =
          await container.read(savedHeartsProvider.notifier).toggle('l1', currentlySaved: false);

      expect(outcome!.status, SaveHeartStatus.failed);
      expect(outcome.failed, isTrue);
      expect(hearts()['l1'], isFalse);
    });

    test('keeps the heart saved when removing fails', () async {
      repository.onRemove = (id) async => throw _offline;

      final outcome =
          await container.read(savedHeartsProvider.notifier).toggle('l1', currentlySaved: true);

      expect(outcome!.status, SaveHeartStatus.failed);
      expect(hearts()['l1'], isTrue);
    });

    test('reports the limit with the number and puts the heart back', () async {
      repository.onSave = (id) async => throw const SavedListingLimitReached(200);

      final outcome =
          await container.read(savedHeartsProvider.notifier).toggle('l1', currentlySaved: false);

      expect(outcome!.status, SaveHeartStatus.limitReached);
      expect(outcome.max, 200);
      expect(hearts()['l1'], isFalse);
    });

    test('shows not saved when the listing is no longer available', () async {
      repository.onSave = (id) async => throw const SavedListingUnavailable();

      final outcome =
          await container.read(savedHeartsProvider.notifier).toggle('l1', currentlySaved: false);

      expect(outcome!.status, SaveHeartStatus.unavailable);
      expect(hearts()['l1'], isFalse);
    });

    test('sends one request for rapid taps on the same listing', () async {
      final pending = Completer<void>();
      repository.onSave = (id) => pending.future;
      final notifier = container.read(savedHeartsProvider.notifier);

      final first = notifier.toggle('l1', currentlySaved: false);
      final second = await notifier.toggle('l1', currentlySaved: false);
      pending.complete();
      await first;

      expect(second, isNull);
      expect(repository.saved, ['l1']);
    });

    test('markRemoved shows not saved everywhere', () {
      container.read(savedHeartsProvider.notifier).markRemoved('l1');

      expect(hearts()['l1'], isFalse);
    });
  });

  group('SavedItemsController', () {
    late FakeSavedListingsRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeSavedListingsRepository();
      repository.onList = (page) async => savedPage(
            [savedListingJson('a'), savedListingJson('b'), savedListingJson('c')],
            hasNext: true,
            total: 5,
          );
      container = ProviderContainer(
        overrides: [savedListingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
    });

    Future<SavedItemsState> open() async {
      container.listen(savedItemsControllerProvider, (previous, next) {});
      return container.read(savedItemsControllerProvider.future);
    }

    SavedItemsState current() => container.read(savedItemsControllerProvider).requireValue;

    test('loads the first page', () async {
      final state = await open();

      expect(state.items.map((i) => i.id), ['a', 'b', 'c']);
      expect(state.hasNext, isTrue);
      expect(state.maxSaved, 200);
      expect(repository.listed, [0]);
    });

    test('appends the next page without repeating an item', () async {
      await open();
      repository.onList = (page) async => savedPage(
            [savedListingJson('c'), savedListingJson('d')],
            page: 1,
            total: 4,
          );

      final ok = await container.read(savedItemsControllerProvider.notifier).loadMore();

      expect(ok, isTrue);
      expect(current().items.map((i) => i.id), ['a', 'b', 'c', 'd']);
      expect(current().hasNext, isFalse);
      expect(current().page, 1);
      expect(current().loadingMore, isFalse);
    });

    test('does nothing when there is no next page', () async {
      repository.onList = (page) async => savedPage([savedListingJson('a')]);
      await open();

      final ok = await container.read(savedItemsControllerProvider.notifier).loadMore();

      expect(ok, isTrue);
      expect(repository.listed, [0]);
    });

    test('reports a failed page and lets the buyer try again', () async {
      await open();
      repository.onList = (page) async => throw _offline;

      final ok = await container.read(savedItemsControllerProvider.notifier).loadMore();

      expect(ok, isFalse);
      expect(current().items, hasLength(3));
      expect(current().loadingMore, isFalse);
    });

    test('removes an item at once and tells the hearts', () async {
      await open();

      final ok = await container.read(savedItemsControllerProvider.notifier).remove('b');

      expect(ok, isTrue);
      expect(current().items.map((i) => i.id), ['a', 'c']);
      expect(repository.removed, ['b']);
      expect(container.read(savedHeartsProvider)['b'], isFalse);
    });

    test('puts the item back where it was when the server refuses', () async {
      await open();
      repository.onRemove = (id) async => throw _offline;

      final ok = await container.read(savedItemsControllerProvider.notifier).remove('b');

      expect(ok, isFalse);
      expect(current().items.map((i) => i.id), ['a', 'b', 'c']);
    });

    test('ignores removing an item that is not in the list', () async {
      await open();

      final ok = await container.read(savedItemsControllerProvider.notifier).remove('zzz');

      expect(ok, isTrue);
      expect(repository.removed, isEmpty);
    });
  });
}
