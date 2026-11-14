import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/saved_searches/data/saved_searches_repository.dart';
import 'package:valuex_mobile/features/saved_searches/domain/saved_search.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';
import 'package:valuex_mobile/features/search/domain/search_sort.dart';
import 'package:valuex_mobile/features/search/domain/transaction_intent.dart';

import 'saved_search_fixtures.dart';

class _FakeApi extends Fake implements ApiClient {
  String? path;
  Object? body;
  Object? response;
  int? status = 201;
  ApiError? error;
  String? method;

  @override
  Future<(T, int?)> postWithStatus<T>(
    String path, {
    Object? data,
    T Function(Object? data)? parse,
  }) async {
    method = 'POST';
    this.path = path;
    body = data;
    if (error != null) throw error!;
    return (parse!(response), status);
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
    return parse!(response);
  }

  @override
  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    method = 'PATCH';
    this.path = path;
    body = data;
    return parse!(response);
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
}

ApiError _coded(String code, {Map<String, String> details = const {}}) => ApiError(
      type: ApiErrorType.business,
      message: 'x',
      code: code,
      statusCode: 409,
      details: details,
    );

void main() {
  group('SavedSearch.fromJson', () {
    test('rebuilds the criteria, splitting facets on the first colon', () {
      final search = SavedSearch.fromJson(savedSearchJson('s1'));

      expect(search.id, 's1');
      expect(search.name, 'Phones in Pune');
      expect(search.alertsEnabled, isTrue);
      expect(search.valid, isTrue);
      expect(search.invalidMessage, isNull);
      expect(search.lastAlertAt, DateTime.utc(2026, 11, 13, 4, 30));
      expect(search.createdAt, DateTime.utc(2026, 11, 10, 9));
      final criteria = search.criteria;
      expect(criteria.query, 'iphone');
      expect(criteria.categoryCode, 'CAT-1');
      expect(criteria.categoryName, 'Smartphones');
      expect(criteria.categoryLevel, 3);
      expect(criteria.realEstate, isFalse);
      expect(criteria.facets, {'brand': 'apple', 'storage_gb': '32..128'});
      expect(criteria.priceMin, 100);
      expect(criteria.priceMax, 900.5);
      expect(criteria.conditions, {'GOOD', 'NEW'});
      expect(criteria.city, 'Pune');
      expect(criteria.state, 'Maharashtra');
      expect(criteria.sort, SearchSort.relevance);
    });

    test('keeps the Real Estate intent and flag and the invalid message', () {
      final search = SavedSearch.fromJson(
        savedSearchJson(
          's2',
          valid: false,
          realEstate: true,
          categoryName: 'Homes',
          categoryLevel: 2,
          criteria: {'category': 'L2-H', 'transactionIntent': 'RENT'},
        ),
      );

      expect(search.valid, isFalse);
      expect(search.invalidMessage, 'Search criteria no longer valid');
      expect(search.criteria.intent, TransactionIntent.rent);
      expect(search.criteria.realEstate, isTrue);
      expect(search.criteria.query, '');
      expect(search.criteria.facets, isEmpty);
      expect(search.criteria.conditions, isEmpty);
    });

    test('survives missing optional fields', () {
      final search = SavedSearch.fromJson(const {
        'id': 's3',
        'criteria': {
          'query': 'chair',
          'facet': ['nocolon', ':empty'],
          'priceMin': 'x'
        },
      });

      expect(search.name, '');
      expect(search.alertsEnabled, isTrue);
      expect(search.valid, isTrue);
      expect(search.criteria.facets, isEmpty);
      expect(search.criteria.priceMin, isNull);
      expect(search.categoryNameOrNull, isNull);
    });

    test('copyWith changes only the alerts switch', () {
      final search = SavedSearch.fromJson(savedSearchJson('s1'));
      final off = search.copyWith(alertsEnabled: false);

      expect(off.alertsEnabled, isFalse);
      expect(off.id, search.id);
      expect(off.criteria, search.criteria);
      expect(off, isNot(search));
      expect(off.copyWith(alertsEnabled: true), search);
      expect(off.hashCode, isNot(search.hashCode));
    });
  });

  group('the request body', () {
    test('holds the saved fields and never the sort, source or near place', () {
      const criteria = SearchCriteria(
        query: ' iphone ',
        categoryCode: 'CAT-1',
        categoryName: 'Smartphones',
        categoryLevel: 3,
        intent: TransactionIntent.sale,
        priceMin: 100,
        priceMax: 900.5,
        conditions: {'NEW', 'GOOD'},
        state: 'Maharashtra',
        city: 'Pune',
        facets: {'brand': 'apple', 'storage_gb': '32..128'},
        sort: SearchSort.newest,
      );

      final body = savedSearchCriteriaBody(criteria);

      expect(body, {
        'query': 'iphone',
        'category': 'CAT-1',
        'transactionIntent': 'SALE',
        'priceMin': '100',
        'priceMax': '900.50',
        'condition': ['GOOD', 'NEW'],
        'state': 'Maharashtra',
        'city': 'Pune',
        'facet': ['brand:apple', 'storage_gb:32..128'],
      });
      for (final never in ['sort', 'source', 'nearCity', 'nearState']) {
        expect(body.containsKey(never), isFalse, reason: never);
      }
    });

    test('round trips through the saved search', () {
      const criteria = SearchCriteria(
        query: 'sofa',
        categoryCode: 'CAT-2',
        priceMax: 5000,
        facets: {'material': 'wood'},
      );
      final json = savedSearchJson('s1', criteria: savedSearchCriteriaBody(criteria));

      final back = SavedSearch.fromJson(json).criteria;

      expect(back.query, 'sofa');
      expect(back.categoryCode, 'CAT-2');
      expect(back.priceMax, 5000);
      expect(back.facets, {'material': 'wood'});
    });

    test('can be saved only with something to save and a chosen intent', () {
      expect(canSaveSearch(const SearchCriteria()), isFalse);
      expect(canSaveSearch(const SearchCriteria(query: '  ')), isFalse);
      expect(canSaveSearch(const SearchCriteria(browseAll: true)), isFalse);
      expect(canSaveSearch(const SearchCriteria(query: 'chair')), isTrue);
      expect(canSaveSearch(const SearchCriteria(categoryCode: 'CAT-1')), isTrue);
      expect(canSaveSearch(const SearchCriteria(priceMin: 1)), isTrue);
      expect(
        canSaveSearch(const SearchCriteria(categoryCode: 'L1-R', realEstate: true)),
        isFalse,
      );
      expect(
        canSaveSearch(
          const SearchCriteria(
            categoryCode: 'L1-R',
            realEstate: true,
            intent: TransactionIntent.rent,
          ),
        ),
        isTrue,
      );
    });
  });

  group('repository', () {
    late _FakeApi api;
    late SavedSearchesRepository repository;

    setUp(() {
      api = _FakeApi();
      repository = SavedSearchesRepository(api);
    });

    test('creates with the criteria body and an optional trimmed name', () async {
      api.response = savedSearchJson('s1');

      final result = await repository.create(
        const SearchCriteria(query: 'iphone', sort: SearchSort.newest),
        name: ' My phones ',
      );

      expect(api.path, '/search/saved');
      expect(api.body, {
        'name': 'My phones',
        'criteria': {'query': 'iphone'},
      });
      expect(result.alreadySaved, isFalse);
      expect(result.search.id, 's1');

      await repository.create(const SearchCriteria(query: 'iphone'), name: '  ');
      expect((api.body! as Map).containsKey('name'), isFalse);
    });

    test('tells an already saved search (HTTP 200) from a new one (201)', () async {
      api.response = savedSearchJson('s1');
      api.status = 200;

      final result = await repository.create(const SearchCriteria(query: 'iphone'));

      expect(result.alreadySaved, isTrue);
    });

    test('maps the limit and invalid criteria errors to typed errors', () async {
      api.error = _coded('ERROR_MAX_SAVED_SEARCHES', details: {'max': '10'});
      await expectLater(
        repository.create(const SearchCriteria(query: 'x')),
        throwsA(isA<SavedSearchLimitReached>().having((e) => e.max, 'max', 10)),
      );

      api.error = _coded('ERROR_MAX_SAVED_SEARCHES');
      await expectLater(
        repository.create(const SearchCriteria(query: 'x')),
        throwsA(isA<SavedSearchLimitReached>().having((e) => e.max, 'max', isNull)),
      );

      api.error = _coded('ERROR_INVALID_CRITERIA');
      await expectLater(
        repository.create(const SearchCriteria(query: 'x')),
        throwsA(isA<SavedSearchInvalidCriteria>()),
      );

      api.error = const ApiError(type: ApiErrorType.network, message: 'offline');
      await expectLater(
        repository.create(const SearchCriteria(query: 'x')),
        throwsA(isA<ApiError>()),
      );
    });

    test('lists, switches alerts and deletes on the saved search paths', () async {
      api.response = [savedSearchJson('s1'), savedSearchJson('s2')];
      final list = await repository.list();
      expect(api.path, '/search/saved');
      expect(list.map((s) => s.id), ['s1', 's2']);

      api.response = savedSearchJson('s1', alerts: false);
      final changed = await repository.setAlerts('s1', enabled: false);
      expect(api.method, 'PATCH');
      expect(api.path, '/search/saved/s1');
      expect(api.body, {'alertsEnabled': false});
      expect(changed.alertsEnabled, isFalse);

      await repository.delete('s2');
      expect(api.method, 'DELETE');
      expect(api.path, '/search/saved/s2');
    });

    test('the limit and typed errors print for logs', () {
      expect(const SavedSearchLimitReached(3).toString(), contains('3'));
      expect(const SavedSearchInvalidCriteria().toString(), contains('Invalid'));
    });
  });
}

extension on SavedSearch {
  String? get categoryNameOrNull => criteria.categoryName;
}
