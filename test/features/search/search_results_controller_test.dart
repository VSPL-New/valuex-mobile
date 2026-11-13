import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:valuex_mobile/features/search/domain/search_source.dart';
import 'package:valuex_mobile/features/search/domain/transaction_intent.dart';
import 'package:valuex_mobile/features/search/presentation/providers/search_results_controller.dart';

import 'search_fixtures.dart';

class _KnownPlace extends HomeLocationController {
  @override
  Future<HomeLocationState> build() async => const LocationKnown(
        HomeLocation(area: 'Kothrud', city: 'Pune', state: 'Maharashtra', pincode: '411038'),
      );
}

class _NoPlace extends HomeLocationController {
  @override
  Future<HomeLocationState> build() async => const LocationNeeded(LocationNeed.denied);
}

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

ApiError _coded(String code) =>
    ApiError(type: ApiErrorType.business, message: 'x', code: code, statusCode: 400);

void main() {
  late FakeSearchRepository repository;

  ProviderContainer makeContainer({bool place = true}) {
    final container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(() => place ? _KnownPlace() : _NoPlace()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Home has long loaded its place by the time a search starts.
  void settlePlace(FakeAsync async, ProviderContainer container) {
    container.listen(homeLocationControllerProvider, (previous, next) {});
    async.flushMicrotasks();
  }

  /// Keeps the controller alive, as the screen does.
  SearchState Function() open(
    FakeAsync async,
    ProviderContainer container,
    SearchCriteria initial,
  ) {
    final provider = searchResultsControllerProvider(initial);
    settlePlace(async, container);
    container.listen(provider, (previous, next) {});
    async.flushMicrotasks();
    return () => container.read(provider);
  }

  setUp(() {
    repository = FakeSearchRepository((criteria, page) async => listingsPage(page * 20, 20));
  });

  group('starting', () {
    test('a blank search makes no call and shows nothing', () {
      fakeAsync((async) {
        final state = open(async, makeContainer(), const SearchCriteria());
        async.elapse(const Duration(seconds: 2));

        expect(repository.calls, isEmpty);
        expect(state().isLoading, isFalse);
        expect(state().items, isEmpty);
      });
    });

    test('a search that starts with text loads the first page', () {
      fakeAsync((async) {
        final container = makeContainer();
        final provider = searchResultsControllerProvider(const SearchCriteria(query: 'phone'));
        settlePlace(async, container);
        container.listen(provider, (previous, next) {});

        expect(container.read(provider).isLoading, isTrue);
        async.flushMicrotasks();

        final state = container.read(provider);
        expect(repository.calls, hasLength(1));
        expect(state.items, hasLength(20));
        expect(state.isLoading, isFalse);
        expect(state.hasNext, isTrue);
        expect(state.totalItems, 100);
        expect(state.noResults, isFalse);
      });
    });

    test('only the city and state of the Home place go with the request', () {
      fakeAsync((async) {
        open(async, makeContainer(), const SearchCriteria(query: 'phone'));

        expect(repository.calls.single.nearCity, 'Pune');
        expect(repository.calls.single.nearState, 'Maharashtra');
      });
    });

    test('without a known place nothing about a place is sent', () {
      fakeAsync((async) {
        open(async, makeContainer(place: false), const SearchCriteria(query: 'phone'));

        expect(repository.calls.single.nearCity, isNull);
        expect(repository.calls.single.nearState, isNull);
      });
    });

    test('a Real Estate category waits for an intent and makes no call', () {
      fakeAsync((async) {
        const initial = SearchCriteria(categoryCode: 'L1-RE', realEstate: true);
        final state = open(async, makeContainer(), initial);

        expect(state().needsIntent, isTrue);
        expect(state().isLoading, isFalse);
        expect(repository.calls, isEmpty);
      });
    });

    test('choosing an intent searches with it', () {
      fakeAsync((async) {
        const initial = SearchCriteria(categoryCode: 'L1-RE', realEstate: true);
        final container = makeContainer();
        final state = open(async, container, initial);

        unawaited(
          container
              .read(searchResultsControllerProvider(initial).notifier)
              .chooseIntent(TransactionIntent.rent),
        );
        async.flushMicrotasks();

        expect(repository.calls.single.criteria.intent, TransactionIntent.rent);
        expect(state().needsIntent, isFalse);
        expect(state().items, hasLength(20));
      });
    });
  });

  group('typing', () {
    const blank = SearchCriteria();

    test('searches only after 400 ms without typing, once, for the last text', () {
      fakeAsync((async) {
        final container = makeContainer();
        final state = open(async, container, blank);
        final controller = container.read(searchResultsControllerProvider(blank).notifier);

        controller.setQuery('l');
        async.elapse(const Duration(milliseconds: 300));
        controller.setQuery('lap');
        async.elapse(const Duration(milliseconds: 300));
        controller.setQuery('laptop');
        async.elapse(const Duration(milliseconds: 399));
        expect(repository.calls, isEmpty);

        async.elapse(const Duration(milliseconds: 2));

        expect(repository.calls, hasLength(1));
        expect(repository.calls.single.criteria.query, 'laptop');
        expect(state().items, hasLength(20));
      });
    });

    test('the text is kept at once, before the search runs', () {
      fakeAsync((async) {
        final container = makeContainer();
        final state = open(async, container, blank);

        container.read(searchResultsControllerProvider(blank).notifier).setQuery('abc');

        expect(state().criteria.query, 'abc');
        expect(state().isLoading, isFalse);
      });
    });

    test('pressing search does not wait for the pause', () {
      fakeAsync((async) {
        final container = makeContainer();
        open(async, container, blank);
        final controller = container.read(searchResultsControllerProvider(blank).notifier);

        controller.setQuery('laptop');
        unawaited(controller.submit());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));

        expect(repository.calls, hasLength(1));
      });
    });

    test('clearing the text goes back to the start page without a call', () {
      fakeAsync((async) {
        final container = makeContainer();
        final state = open(async, container, blank);
        final controller = container.read(searchResultsControllerProvider(blank).notifier);

        controller.setQuery('laptop');
        async.elapse(const Duration(milliseconds: 500));
        controller.setQuery('');
        async.elapse(const Duration(milliseconds: 500));

        expect(repository.calls, hasLength(1));
        expect(state().criteria.isBlank, isTrue);
        expect(state().items, isEmpty);
      });
    });

    group('voice search source', () {
      test('preserves criteria and marks only the first page as voice', () {
        fakeAsync((async) {
          const initial = SearchCriteria(
            query: 'old',
            categoryCode: 'CAT-1',
            categoryName: 'Phones',
            categoryLevel: 3,
            priceMin: 100,
            intent: TransactionIntent.sale,
          );
          final container = makeContainer();
          final state = open(async, container, initial);
          final controller = container.read(searchResultsControllerProvider(initial).notifier);
          final before = repository.calls.length;

          unawaited(controller.applyVoiceQuery('new spoken query'));
          async.flushMicrotasks();

          expect(state().criteria.query, 'new spoken query');
          expect(state().criteria.categoryCode, 'CAT-1');
          expect(state().criteria.priceMin, 100);
          expect(state().criteria.intent, TransactionIntent.sale);
          expect(repository.calls[before].source, SearchSource.voice);

          unawaited(controller.loadMore());
          async.flushMicrotasks();
          expect(repository.calls.last.page, 1);
          expect(repository.calls.last.source, SearchSource.typed);

          unawaited(controller.refresh());
          async.flushMicrotasks();
          expect(repository.calls.last.page, 0);
          expect(repository.calls.last.source, SearchSource.typed);
        });
      });

      test('ordinary edits and saved-search criteria never include the source', () {
        const criteria = SearchCriteria(query: 'phone');
        expect(criteria.toQueryParameters().containsKey('source'), isFalse);
        fakeAsync((async) {
          final container = makeContainer();
          open(async, container, const SearchCriteria());
          final controller =
              container.read(searchResultsControllerProvider(const SearchCriteria()).notifier);
          unawaited(controller.applyVoiceQuery('phone'));
          async.flushMicrotasks();
          controller.setQuery('phones');
          async.elapse(const Duration(milliseconds: 401));
          expect(repository.calls.last.source, SearchSource.typed);
        });
      });
    });
  });

  group('stale responses', () {
    test('an answer for older text never replaces the answer for newer text', () {
      fakeAsync((async) {
        final answers = <String, Completer<SearchPage>>{};
        repository.handler =
            (criteria, page) => (answers[criteria.query] = Completer<SearchPage>()).future;
        const blank = SearchCriteria();
        final container = makeContainer();
        final state = open(async, container, blank);
        final controller = container.read(searchResultsControllerProvider(blank).notifier);

        controller.setQuery('lap');
        async.elapse(const Duration(milliseconds: 450));
        controller.setQuery('laptop');
        async.elapse(const Duration(milliseconds: 450));
        expect(answers.keys, ['lap', 'laptop']);

        answers['laptop']!.complete(listingsPage(500, 3, total: 3, hasNext: false));
        async.flushMicrotasks();
        answers['lap']!.complete(listingsPage(900, 7, total: 7, hasNext: false));
        async.flushMicrotasks();

        expect(state().items.map((i) => i.id), ['l500', 'l501', 'l502']);
        expect(state().criteria.query, 'laptop');
        expect(state().isLoading, isFalse);
      });
    });

    test('a failure of an older request is ignored too', () {
      fakeAsync((async) {
        final answers = <String, Completer<SearchPage>>{};
        repository.handler =
            (criteria, page) => (answers[criteria.query] = Completer<SearchPage>()).future;
        const blank = SearchCriteria();
        final container = makeContainer();
        final state = open(async, container, blank);
        final controller = container.read(searchResultsControllerProvider(blank).notifier);

        controller.setQuery('a');
        async.elapse(const Duration(milliseconds: 450));
        controller.setQuery('ab');
        async.elapse(const Duration(milliseconds: 450));
        answers['ab']!.complete(listingsPage(0, 2, total: 2, hasNext: false));
        async.flushMicrotasks();
        answers['a']!.completeError(_offline);
        async.flushMicrotasks();

        expect(state().error, isNull);
        expect(state().items, hasLength(2));
      });
    });

    test('a page of older criteria is not added after the criteria changed', () {
      fakeAsync((async) {
        final pending = <Completer<SearchPage>>[];
        const initial = SearchCriteria(query: 'phone');
        repository.handler = (criteria, page) {
          if (page == 0) return Future.value(listingsPage(0, 20));
          final completer = Completer<SearchPage>();
          pending.add(completer);
          return completer.future;
        };
        final container = makeContainer();
        final state = open(async, container, initial);
        final controller = container.read(searchResultsControllerProvider(initial).notifier);

        unawaited(controller.loadMore());
        async.flushMicrotasks();
        unawaited(controller.applyCriteria(initial.copyWith(priceMax: 10)));
        async.flushMicrotasks();
        pending.single.complete(listingsPage(20, 20, page: 1));
        async.flushMicrotasks();

        expect(state().items, hasLength(20));
        expect(state().items.first.id, 'l0');
        expect(state().criteria.priceMax, 10);
        expect(state().isLoadingMore, isFalse);
      });
    });
  });

  group('paging', () {
    const initial = SearchCriteria(query: 'phone');

    test('more pages are added below, asking for the next page each time', () {
      fakeAsync((async) {
        final container = makeContainer();
        final state = open(async, container, initial);
        final controller = container.read(searchResultsControllerProvider(initial).notifier);

        unawaited(controller.loadMore());
        async.flushMicrotasks();
        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(repository.calls.map((c) => c.page), [0, 1, 2]);
        expect(state().items, hasLength(60));
        expect(state().nextPage, 3);
      });
    });

    test('nothing more is asked while a page is loading or when there is no next page', () {
      fakeAsync((async) {
        final gate = Completer<SearchPage>();
        repository.handler = (criteria, page) =>
            page == 0 ? Future.value(listingsPage(0, 20, hasNext: true)) : gate.future;
        final container = makeContainer();
        final state = open(async, container, initial);
        final controller = container.read(searchResultsControllerProvider(initial).notifier);

        unawaited(controller.loadMore());
        async.flushMicrotasks();
        expect(state().isLoadingMore, isTrue);
        unawaited(controller.loadMore());
        async.flushMicrotasks();
        expect(repository.calls, hasLength(2));

        gate.complete(listingsPage(20, 5, total: 25, hasNext: false, page: 1));
        async.flushMicrotasks();
        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(repository.calls, hasLength(2));
        expect(state().items, hasLength(25));
        expect(state().hasNext, isFalse);
      });
    });

    test('a listing that comes again on a later page is shown once', () {
      fakeAsync((async) {
        repository.handler = (criteria, page) async =>
            page == 0 ? listingsPage(0, 20) : listingsPage(18, 5, page: 1);
        final container = makeContainer();
        final state = open(async, container, initial);

        unawaited(container.read(searchResultsControllerProvider(initial).notifier).loadMore());
        async.flushMicrotasks();

        expect(state().items, hasLength(23));
        expect(state().items.map((i) => i.id).toSet(), hasLength(23));
      });
    });

    test('a failed page keeps the results and can be tried again', () {
      fakeAsync((async) {
        var fail = true;
        repository.handler = (criteria, page) async {
          if (page == 0) return listingsPage(0, 20);
          if (fail) throw _offline;
          return listingsPage(20, 20, page: 1);
        };
        final container = makeContainer();
        final state = open(async, container, initial);
        final controller = container.read(searchResultsControllerProvider(initial).notifier);

        unawaited(controller.loadMore());
        async.flushMicrotasks();
        expect(state().loadMoreFailed, isTrue);
        expect(state().isLoadingMore, isFalse);
        expect(state().items, hasLength(20));
        expect(state().hasNext, isTrue);

        fail = false;
        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(state().loadMoreFailed, isFalse);
        expect(state().items, hasLength(40));
      });
    });
  });

  group('results', () {
    const initial = SearchCriteria(query: 'phone');

    test('an empty first page is the no-results state', () {
      fakeAsync((async) {
        repository.handler = (criteria, page) async => SearchPage.fromJson(
              pageJson([], advisory: 'NO_RESULTS_FOUND'),
            );
        final state = open(async, makeContainer(), initial);

        expect(state().noResults, isTrue);
        expect(state().items, isEmpty);
        expect(state().isLoading, isFalse);
      });
    });

    test('a failed first page shows the error and Retry loads it again', () {
      fakeAsync((async) {
        var fail = true;
        repository.handler = (criteria, page) async {
          if (fail) {
            throw const ApiError(type: ApiErrorType.server, message: 'down', statusCode: 503);
          }
          return listingsPage(0, 20);
        };
        final container = makeContainer();
        final state = open(async, container, initial);

        expect(state().error, isA<ApiError>());
        expect(state().isLoading, isFalse);

        fail = false;
        unawaited(container.read(searchResultsControllerProvider(initial).notifier).retry());
        async.flushMicrotasks();

        expect(state().error, isNull);
        expect(state().items, hasLength(20));
      });
    });

    test('the facets of an L3 category come with the first page', () {
      fakeAsync((async) {
        repository.handler = (criteria, page) async => SearchPage.fromJson(
              pageJson([listingJson('l1')], facets: List.of(facetsJson)),
            );
        final state = open(
          async,
          makeContainer(),
          const SearchCriteria(categoryCode: 'CAT-1', categoryLevel: 3),
        );

        expect(state().facets.map((f) => f.key), ['brand', 'storage_gb', 'dual_sim']);
      });
    });

    test('applying criteria searches again from the first page and drops the old results', () {
      fakeAsync((async) {
        final gate = Completer<SearchPage>();
        final container = makeContainer();
        final state = open(async, container, initial);
        final controller = container.read(searchResultsControllerProvider(initial).notifier);
        repository.handler = (criteria, page) => gate.future;

        unawaited(controller.applyCriteria(initial.copyWith(priceMin: 5, conditions: {'GOOD'})));
        async.flushMicrotasks();

        expect(state().items, isEmpty);
        expect(state().isLoading, isTrue);
        expect(repository.calls.last.page, 0);
        expect(repository.calls.last.criteria.conditions, {'GOOD'});

        gate.complete(listingsPage(0, 3, total: 3, hasNext: false));
        async.flushMicrotasks();
        expect(state().items, hasLength(3));
      });
    });

    test('refreshing keeps the results on screen until the new page arrives', () {
      fakeAsync((async) {
        final container = makeContainer();
        final state = open(async, container, initial);
        final controller = container.read(searchResultsControllerProvider(initial).notifier);
        final gate = Completer<SearchPage>();
        repository.handler = (criteria, page) => gate.future;

        unawaited(controller.refresh());
        async.flushMicrotasks();
        expect(state().items, hasLength(20));
        expect(state().isLoading, isTrue);

        gate.complete(listingsPage(100, 2, total: 2, hasNext: false));
        async.flushMicrotasks();
        expect(state().items.map((i) => i.id), ['l100', 'l101']);
      });
    });

    test('clearing the filters searches again with the text and category kept', () {
      fakeAsync((async) {
        const criteria = SearchCriteria(
          query: 'phone',
          categoryCode: 'CAT-1',
          categoryLevel: 3,
          priceMax: 10,
          state: 'Goa',
        );
        final container = makeContainer();
        final state = open(async, container, criteria);

        unawaited(
          container.read(searchResultsControllerProvider(criteria).notifier).clearFilters(),
        );
        async.flushMicrotasks();

        expect(repository.calls.last.criteria.hasFilters, isFalse);
        expect(repository.calls.last.criteria.query, 'phone');
        expect(repository.calls.last.criteria.categoryCode, 'CAT-1');
        expect(state().criteria.hasFilters, isFalse);
      });
    });
  });

  group('Real Estate intent', () {
    test('ERROR_INTENT_REQUIRED from the server asks for the intent instead of failing', () {
      fakeAsync((async) {
        repository.handler = (criteria, page) async => throw _coded('ERROR_INTENT_REQUIRED');
        const initial = SearchCriteria(categoryCode: 'L2-X', categoryLevel: 2);
        final state = open(async, makeContainer(), initial);

        expect(state().needsIntent, isTrue);
        expect(state().criteria.realEstate, isTrue);
        expect(state().criteria.intent, isNull);
        expect(state().error, isNull);
        expect(state().isLoading, isFalse);
      });
    });

    test('after the intent is chosen the search is repeated with it', () {
      fakeAsync((async) {
        repository.handler = (criteria, page) async => criteria.intent == null
            ? throw _coded('ERROR_INTENT_REQUIRED')
            : listingsPage(0, 4, total: 4, hasNext: false);
        const initial = SearchCriteria(categoryCode: 'L2-X', categoryLevel: 2);
        final container = makeContainer();
        final state = open(async, container, initial);

        unawaited(
          container
              .read(searchResultsControllerProvider(initial).notifier)
              .chooseIntent(TransactionIntent.lease),
        );
        async.flushMicrotasks();

        expect(repository.calls.last.criteria.intent, TransactionIntent.lease);
        expect(state().needsIntent, isFalse);
        expect(state().items, hasLength(4));
      });
    });
  });

  test('typing after the controller is gone does nothing', () {
    fakeAsync((async) {
      final container = makeContainer();
      const initial = SearchCriteria(query: 'phone');
      final provider = searchResultsControllerProvider(initial);
      final subscription = container.listen(provider, (previous, next) {});
      async.flushMicrotasks();
      final controller = container.read(provider.notifier);
      controller.setQuery('phones');

      subscription.close();
      async.elapse(const Duration(seconds: 2));

      expect(repository.calls, hasLength(1));
      expect(() => controller.load(), returnsNormally);
    });
  });
}
