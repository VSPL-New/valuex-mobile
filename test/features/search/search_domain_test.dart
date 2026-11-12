import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/network/api_error_messages.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';
import 'package:valuex_mobile/features/search/domain/search_facet.dart';
import 'package:valuex_mobile/features/search/domain/search_listing.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:valuex_mobile/features/search/domain/search_sort.dart';
import 'package:valuex_mobile/features/search/domain/search_suggestion.dart';
import 'package:valuex_mobile/features/search/domain/transaction_intent.dart';
import 'package:valuex_mobile/features/search/presentation/search_labels.dart';
import 'package:valuex_mobile/features/search/presentation/search_routes.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import 'search_fixtures.dart';

void main() {
  group('SearchCriteria', () {
    test('a new one is blank and has no filters', () {
      const criteria = SearchCriteria();

      expect(criteria.isBlank, isTrue);
      expect(criteria.hasFilters, isFalse);
      expect(criteria.filterCount, 0);
      expect(criteria.toQueryParameters(), isEmpty);
    });

    test('text, a category, browse all or any filter makes it a search', () {
      expect(const SearchCriteria(query: 'phone').isBlank, isFalse);
      expect(const SearchCriteria(query: '   ').isBlank, isTrue);
      expect(const SearchCriteria(categoryCode: 'C').isBlank, isFalse);
      expect(const SearchCriteria(browseAll: true).isBlank, isFalse);
      expect(const SearchCriteria(priceMax: 10).isBlank, isFalse);
    });

    test('it counts filter groups, with one per facet', () {
      const criteria = SearchCriteria(
        priceMin: 1,
        priceMax: 5,
        conditions: {'GOOD', 'FAIR'},
        state: 'Goa',
        city: 'Panaji',
        facets: {'brand': 'apple', 'dual_sim': 'true'},
      );

      expect(criteria.filterCount, 6);
    });

    test('equal criteria are equal and hash the same, whatever the order of sets and maps', () {
      const a = SearchCriteria(
        conditions: {'GOOD', 'FAIR'},
        facets: {'a': '1', 'b': '2'},
        categoryCode: 'C',
      );
      const b = SearchCriteria(
        conditions: {'FAIR', 'GOOD'},
        facets: {'b': '2', 'a': '1'},
        categoryCode: 'C',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == b.copyWith(sort: SearchSort.newest), isFalse);
      expect(a == b.copyWith(browseAll: true), isFalse);
      expect(a == b.copyWith(realEstate: true), isFalse);
      expect(a == b.copyWith(priceMin: 1.0), isFalse);
      expect(a == b.copyWith(categoryName: 'N'), isFalse);
    });

    test('copyWith can set a nullable field and clear it again', () {
      final set = const SearchCriteria().copyWith(
        categoryCode: 'C',
        categoryName: 'Phones',
        categoryLevel: 3,
        intent: TransactionIntent.rent,
        priceMin: 5.5,
        priceMax: 9.0,
        state: 'Goa',
        city: 'Panaji',
      );

      expect(set.categoryLevel, 3);
      expect(set.isLeafCategory, isTrue);
      expect(set.intent, TransactionIntent.rent);
      expect(set.copyWith(query: 'x').priceMin, 5.5);

      final cleared = set.copyWith(
        categoryCode: null,
        categoryName: null,
        categoryLevel: null,
        intent: null,
        priceMin: null,
        priceMax: null,
        state: null,
        city: null,
      );
      expect(cleared, const SearchCriteria());
    });

    test('clearing filters keeps the text, the category, the intent and the sort', () {
      const criteria = SearchCriteria(
        query: 'flat',
        categoryCode: 'C',
        realEstate: true,
        intent: TransactionIntent.lease,
        sort: SearchSort.newest,
        priceMin: 1,
        conditions: {'GOOD'},
        state: 'Goa',
        city: 'Panaji',
        facets: {'a': '1'},
      );

      final cleared = criteria.withoutFilters();

      expect(cleared.hasFilters, isFalse);
      expect(cleared.query, 'flat');
      expect(cleared.categoryCode, 'C');
      expect(cleared.intent, TransactionIntent.lease);
      expect(cleared.sort, SearchSort.newest);
    });

    test('a Real Estate scope needs an intent and takes no condition filter', () {
      const criteria = SearchCriteria(realEstate: true, categoryCode: 'C');

      expect(criteria.needsIntent, isTrue);
      expect(criteria.allowsConditions, isFalse);
      expect(criteria.copyWith(intent: TransactionIntent.sale).needsIntent, isFalse);
      expect(const SearchCriteria().allowsConditions, isTrue);
    });

    test('it writes the request parameters in the server grammar', () {
      const criteria = SearchCriteria(
        query: '  iphone 14  ',
        categoryCode: 'CAT-0001',
        intent: TransactionIntent.sale,
        priceMin: 1500,
        priceMax: 42000.5,
        conditions: {'LIKE_NEW', 'GOOD'},
        state: 'Maharashtra',
        city: 'Pune',
        facets: {'brand': 'apple', 'storage_gb': '16..512', 'dual_sim': 'true'},
        sort: SearchSort.priceDesc,
      );

      expect(criteria.toQueryParameters(), {
        'query': 'iphone 14',
        'category': 'CAT-0001',
        'transactionIntent': 'SALE',
        'priceMin': '1500',
        'priceMax': '42000.50',
        'condition': ['GOOD', 'LIKE_NEW'],
        'state': 'Maharashtra',
        'city': 'Pune',
        'facet': ['brand:apple', 'storage_gb:16..512', 'dual_sim:true'],
        'sort': 'PRICE_DESC',
      });
    });

    test('prices keep their paise', () {
      expect(SearchCriteria.formatPrice(1299.99), '1299.99');
      expect(SearchCriteria.formatPrice(0.1 + 0.2), '0.30');
      expect(SearchCriteria.formatPrice(500), '500');
      expect(SearchCriteria.formatPrice(500.10), '500.10');
    });
  });

  group('models', () {
    test('a listing reads the card of the API contract, with decimal prices', () {
      final listing = SearchListing.fromJson(
        listingJson(
          'l1',
          price: 1299.5,
          qualifier: 'STARTING_FROM',
          intent: 'RENT',
          rating: 4,
          badge: 'FEATURED',
        ),
      );

      expect(listing.id, 'l1');
      expect(listing.price, 1299.5);
      expect(listing.startingFrom, isTrue);
      expect(listing.transactionIntent, TransactionIntent.rent);
      expect(listing.sellerRating, 4.0);
      expect(listing.badge, SearchBadge.featured);
      expect(listing.cardUrl, 'https://media.example/card.jpg');
      expect(listing.thumbnailUrl, 'https://media.example/thumb.jpg');
      expect(listing.categoryName, 'Smartphones');
      expect(listing.publishedAt, DateTime.utc(2026, 11, 9, 9));
      expect(listing.saved, isFalse);
    });

    test('a listing may have no photo, price, condition, rating or badge', () {
      final listing = SearchListing.fromJson(
        listingJson('l2', price: null, condition: null, cardUrl: null)..remove('category'),
      );

      expect(listing.price, isNull);
      expect(listing.condition, isNull);
      expect(listing.cardUrl, isNull);
      expect(listing.badge, isNull);
      expect(listing.categoryName, isNull);
      expect(listing.startingFrom, isFalse);
    });

    test('a page reads its paging, the intent, the facets and the advisory', () {
      final page = SearchPage.fromJson(
        pageJson(
          [listingJson('l1')],
          total: 134,
          hasNext: true,
          facets: List.of(facetsJson),
          appliedIntent: 'LEASE',
        ),
      );

      expect(page.items, hasLength(1));
      expect(page.totalItems, 134);
      expect(page.hasNext, isTrue);
      expect(page.appliedIntent, TransactionIntent.lease);
      expect(page.advisoryCode, isNull);
      expect(
          page.facets.map((f) => f.type), [FacetType.option, FacetType.number, FacetType.boolean]);
      expect(page.facets.first.buckets.last.label, 'Samsung');
      expect(page.facets.first.buckets.last.count, 12);
      expect(page.facets[1].min, 16);
      expect(page.facets[1].max, 512);
    });

    test('an empty first page carries the no-results advisory', () {
      final page = SearchPage.fromJson(pageJson([], advisory: 'NO_RESULTS_FOUND'));

      expect(page.items, isEmpty);
      expect(page.advisoryCode, 'NO_RESULTS_FOUND');
    });

    test('missing optional parts of a page fall back to safe values', () {
      final page = SearchPage.fromJson({'items': null});
      final facet = SearchFacet.fromJson({'key': 'k', 'type': 'OTHER'});

      expect(page.items, isEmpty);
      expect(page.hasNext, isFalse);
      expect(page.totalItems, 0);
      expect(facet.label, 'k');
      expect(facet.type, FacetType.option);
      expect(FacetBucket.fromJson({'code': 'c'}).label, 'c');
    });

    test('intents and badges read the server codes', () {
      expect(TransactionIntent.fromApi('SALE'), TransactionIntent.sale);
      expect(TransactionIntent.fromApi('nope'), isNull);
      expect(SearchBadge.fromApi('BOOSTED'), SearchBadge.boosted);
      expect(SearchBadge.fromApi(null), isNull);
    });

    test('a search listing becomes a Home card with its photo, badge and condition', () {
      final card = SearchListing.fromJson(
        listingJson('l1', price: 99.5, qualifier: 'STARTING_FROM', badge: 'BOOSTED', rating: 4.5),
      ).toCardListing();

      expect(card.id, 'l1');
      expect(card.priceInr, 99.5);
      expect(card.image, 'https://media.example/card.jpg');
      expect(card.isBoosted, isTrue);
      expect(card.isFeatured, isFalse);
      expect(card.startingFrom, isTrue);
      expect(card.sellerRating, 4.5);
      expect(card.condition?.name, 'good');
    });

    test('the card falls back to the thumbnail, an empty image and no condition', () {
      final thumbOnly = SearchListing.fromJson({
        ...listingJson('l1', condition: 'MYSTERY'),
        'photo': {'thumbnailUrl': 'https://media.example/thumb.jpg'},
      }).toCardListing();
      final none =
          SearchListing.fromJson(listingJson('l2', cardUrl: null, condition: null)).toCardListing();

      expect(thumbOnly.image, 'https://media.example/thumb.jpg');
      expect(thumbOnly.condition, isNull);
      expect(none.image, '');
      for (final code in ['NEW', 'LIKE_NEW', 'GOOD', 'FAIR', 'POOR']) {
        expect(
          SearchListing.fromJson(listingJson('x', condition: code)).toCardListing().condition,
          isNotNull,
          reason: code,
        );
      }
    });
  });

  group('routes', () {
    test('a search location carries its text, category and intent and reads back', () {
      final location = searchLocation(
        query: ' laptop ',
        categoryCode: 'CAT-1',
        categoryName: 'Laptops & PCs',
        categoryLevel: 3,
        realEstate: true,
        intent: TransactionIntent.rent,
      );
      final criteria = searchCriteriaFromParams(Uri.parse(location).queryParameters);

      expect(Uri.parse(location).path, '/search');
      expect(criteria.query, 'laptop');
      expect(criteria.categoryCode, 'CAT-1');
      expect(criteria.categoryName, 'Laptops & PCs');
      expect(criteria.categoryLevel, 3);
      expect(criteria.realEstate, isTrue);
      expect(criteria.intent, TransactionIntent.rent);
    });

    test('a plain search location has no query string', () {
      expect(searchLocation(), '/search');
      expect(searchCriteriaFromParams(const {}), const SearchCriteria());
      expect(searchCriteriaFromParams(const {'all': 'true'}).browseAll, isTrue);
      expect(searchLocation(browseAll: true), '/search?all=true');
    });

    test('text from a link is cut at the limit', () {
      final criteria = searchCriteriaFromParams({'q': 'a' * 500});

      expect(criteria.query.length, SearchCriteria.maxQueryLength);
    });

    test('the browse location carries the parent', () {
      final location = categoryBrowseLocation(
        parentCode: 'L1-A',
        parentName: 'Real Estate',
        parentLevel: 1,
        realEstate: true,
      );
      final params = Uri.parse(location).queryParameters;

      expect(Uri.parse(location).path, '/search/categories');
      expect(params, {'parent': 'L1-A', 'name': 'Real Estate', 'level': '1', 'realEstate': 'true'});
      expect(categoryBrowseLocation(), '/search/categories');
    });

    test('only the top-level Real Estate category is recognised as Real Estate', () {
      const realEstate =
          CategoryNode(code: 'L1', name: ' Real Estate ', level: 1, hasChildren: true);
      const other = CategoryNode(code: 'L1', name: 'Books', level: 1, hasChildren: true);
      const nested = CategoryNode(code: 'L2', name: 'Real Estate', level: 2, hasChildren: true);

      expect(isRealEstateRoot(realEstate), isTrue);
      expect(isRealEstateRoot(other), isFalse);
      expect(isRealEstateRoot(nested), isFalse);
    });
  });

  group('repository', () {
    late FakeHttpAdapter api;

    SearchRepository repository(FakeHandler handler) {
      api = FakeHttpAdapter(handler);
      return SearchRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
      );
    }

    test('it calls the search endpoint and reads the envelope', () async {
      final repo = repository(
        (_) async => FakeHttpAdapter.ok(pageJson([listingJson('l1')], total: 1)),
      );

      final page = await repo.search(const SearchCriteria(query: 'iphone'));

      expect(page.items.single.title, 'Apple iPhone 14 128GB');
      expect(api.requests.single.path, '/search/listings');
      expect(api.requests.single.method, 'GET');
    });

    test('it sends the criteria, the paging and only the city and state of the place', () async {
      final repo = repository((_) async => FakeHttpAdapter.ok(pageJson([])));

      await repo.search(
        const SearchCriteria(
          query: 'iphone',
          priceMin: 100,
          conditions: {'GOOD', 'NEW'},
          facets: {'brand': 'apple', 'storage_gb': '16..'},
        ),
        page: 2,
        nearCity: 'Pune',
        nearState: 'Maharashtra',
      );

      final uri = api.requests.single.uri;
      expect(uri.queryParametersAll['query'], ['iphone']);
      expect(uri.queryParametersAll['priceMin'], ['100']);
      expect(uri.queryParametersAll['condition'], ['GOOD', 'NEW']);
      expect(uri.queryParametersAll['facet'], ['brand:apple', 'storage_gb:16..']);
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['size'], '20');
      expect(uri.queryParameters['nearCity'], 'Pune');
      expect(uri.queryParameters['nearState'], 'Maharashtra');
      expect(uri.queryParameters.containsKey('includeFacets'), isFalse);
      expect(
        uri.queryParameters.keys.where((k) => k.toLowerCase().contains('lat') || k == 'lng'),
        isEmpty,
      );
    });

    test('facets are asked for only with the first page of an L3 category', () async {
      final repo = repository((_) async => FakeHttpAdapter.ok(pageJson([])));
      const leaf = SearchCriteria(categoryCode: 'CAT-1', categoryLevel: 3);

      await repo.search(leaf);
      await repo.search(leaf, page: 1);
      await repo.search(const SearchCriteria(categoryCode: 'L2', categoryLevel: 2));

      expect(api.requests[0].uri.queryParameters['includeFacets'], 'true');
      expect(api.requests[1].uri.queryParameters.containsKey('includeFacets'), isFalse);
      expect(api.requests[2].uri.queryParameters.containsKey('includeFacets'), isFalse);
    });

    test('a blank place is not sent', () async {
      final repo = repository((_) async => FakeHttpAdapter.ok(pageJson([])));

      await repo.search(const SearchCriteria(query: 'x'), nearCity: '', nearState: null);

      expect(api.requests.single.uri.queryParameters.containsKey('nearCity'), isFalse);
      expect(api.requests.single.uri.queryParameters.containsKey('nearState'), isFalse);
    });

    test('a backend error code comes back as an ApiError with that code', () async {
      final repo = repository(
        (_) async => FakeHttpAdapter.error(400, 'ERROR_INVALID_PRICE_RANGE', 'bad'),
      );

      await expectLater(
        repo.search(const SearchCriteria(query: 'x')),
        throwsA(
          isA<ApiError>()
              .having((e) => e.code, 'code', 'ERROR_INVALID_PRICE_RANGE')
              .having((e) => e.statusCode, 'status', 400),
        ),
      );
    });

    group('suggestions', () {
      test('it calls the suggestions endpoint with the text and the default limit', () async {
        final repo = repository(
          (_) async => FakeHttpAdapter.ok([
            {'text': 'Smartphones', 'type': 'CATEGORY', 'categoryCode': 'CAT-0001'},
            {'text': 'iPhone 14 128GB', 'type': 'LISTING', 'categoryCode': null},
          ]),
        );

        final suggestions = await repo.suggest('smart');

        expect(api.requests.single.path, '/search/suggestions');
        expect(api.requests.single.method, 'GET');
        expect(api.requests.single.uri.queryParameters, {'query': 'smart', 'limit': '8'});
        expect(suggestions, hasLength(2));
        expect(suggestions[0].type, SuggestionType.category);
        expect(suggestions[0].isCategory, isTrue);
        expect(suggestions[0].categoryCode, 'CAT-0001');
        expect(suggestions[1].text, 'iPhone 14 128GB');
        expect(suggestions[1].type, SuggestionType.listing);
        expect(suggestions[1].categoryCode, isNull);
      });

      test('a given limit is sent', () async {
        final repo = repository((_) async => FakeHttpAdapter.ok([]));

        final suggestions = await repo.suggest('ab', limit: 10);

        expect(suggestions, isEmpty);
        expect(api.requests.single.uri.queryParameters['limit'], '10');
      });

      test('entries the app cannot show are left out', () async {
        final repo = repository(
          (_) async => FakeHttpAdapter.ok([
            {'text': 'Phone', 'type': 'LISTING'},
            {'text': 'Plot', 'type': 'PROPERTY'},
            {'text': '  ', 'type': 'LISTING'},
            {'type': 'LISTING'},
            {'text': 'Cars', 'type': 'CATEGORY', 'categoryCode': ''},
            'nonsense',
          ]),
        );

        final suggestions = await repo.suggest('ph');

        expect(suggestions.map((s) => s.text), ['Phone', 'Cars']);
        expect(suggestions.last.categoryCode, isNull);
      });

      test('a payload that is not a list is a server error', () async {
        final repo = repository((_) async => FakeHttpAdapter.ok({'text': 'x'}));

        await expectLater(
          repo.suggest('ph'),
          throwsA(isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.server)),
        );
      });

      test('the error codes come back as ApiErrors', () async {
        final cases = {
          400: 'ERROR_QUERY_TOO_LONG',
          429: 'RATE_LIMITED',
          503: 'ERROR_SEARCH_UNAVAILABLE',
        };
        for (final entry in cases.entries) {
          final repo = repository(
            (_) async => FakeHttpAdapter.error(entry.key, entry.value, 'x'),
          );

          await expectLater(
            repo.suggest('ph'),
            throwsA(
              isA<ApiError>()
                  .having((e) => e.code, 'code', entry.value)
                  .having((e) => e.statusCode, 'status', entry.key),
            ),
            reason: '${entry.key}',
          );
        }
      });

      test('suggestions with the same content are equal', () {
        const a = SearchSuggestion(text: 'x', type: SuggestionType.category, categoryCode: 'C');
        const b = SearchSuggestion(text: 'x', type: SuggestionType.category, categoryCode: 'C');
        const c = SearchSuggestion(text: 'x', type: SuggestionType.listing);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(a, isNot(c));
        expect(SuggestionType.fromApi('LISTING'), SuggestionType.listing);
        expect(SuggestionType.fromApi(null), isNull);
      });
    });
  });

  group('error messages', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final hi = lookupAppLocalizations(const Locale('hi'));

    ApiError coded(String code, {int status = 400}) =>
        ApiError(type: ApiErrorType.business, message: 'x', code: code, statusCode: status);

    test('every search code has its own text in both languages', () {
      final expected = {
        'ERROR_QUERY_TOO_LONG': 'Search text is too long',
        'ERROR_INVALID_PRICE_RANGE': 'Minimum price cannot be above maximum price',
        'ERROR_INVALID_FILTERS': 'Invalid filter combination',
        'ERROR_INTENT_REQUIRED': 'Choose Buy, Rent or Lease',
        'ERROR_INTENT_NOT_SUPPORTED': 'This option is not available for this property type',
        'ERROR_SEARCH_UNAVAILABLE': 'Search is not available right now. Try again',
        'CATEGORY_NOT_FOUND': 'This category is not available',
      };
      for (final entry in expected.entries) {
        expect(searchErrorMessage(en, coded(entry.key)), entry.value, reason: entry.key);
        expect(searchCodeMessage(hi, entry.key), isNot(entry.value), reason: entry.key);
      }
    });

    test('the rate limit is told by its HTTP status', () {
      expect(
        searchErrorMessage(en, coded('RATE_LIMITED', status: 429)),
        'Too many searches. Wait a moment and try again',
      );
      expect(
          searchErrorMessage(hi, coded('RATE_LIMITED', status: 429)), isNot(contains('Too many')));
    });

    test('anything else falls back to the general messages', () {
      expect(searchCodeMessage(en, 'OTHER'), isNull);
      expect(
        searchErrorMessage(en, const ApiError(type: ApiErrorType.network, message: 'x')),
        en.errorUnableToConnect,
      );
      expect(searchErrorMessage(en, coded('OTHER')), en.errorSomethingWentWrong);
      expect(searchErrorMessage(en, StateError('x')), en.errorSomethingWentWrong);
    });

    test('the labels of the intents, sorts and conditions come from the language files', () {
      expect(intentLabel(en, TransactionIntent.sale), 'Buy');
      expect(intentLabel(en, TransactionIntent.rent), 'Rent');
      expect(intentLabel(en, TransactionIntent.lease), 'Lease');
      expect(intentLabel(hi, TransactionIntent.sale), isNot('Buy'));
      expect(
        {for (final sort in SearchSort.values) sortLabel(en, sort)},
        hasLength(SearchSort.values.length),
      );
    });
  });
}
