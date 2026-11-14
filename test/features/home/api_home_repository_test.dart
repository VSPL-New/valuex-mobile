import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/constants/app_assets.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/home/data/api_home_repository.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/domain/entities/listing.dart';
import 'package:valuex_mobile/features/home/domain/entities/promo.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../search/search_fixtures.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

Map<String, dynamic> _promoJson({
  String id = 'p-1',
  String title = 'Used cars sale',
  Object? imageKey = 'home_promo_1',
  Object? target = const {'type': 'CATEGORY', 'value': 'L1-CARS'},
}) =>
    {
      'id': id,
      'badge': 'This week',
      'title': title,
      'body': 'Find your next car',
      'ctaLabel': 'Shop cars',
      'imageKey': imageKey,
      'target': target,
    };

void main() {
  const pune = HomeLocation(
    area: 'Shivajinagar',
    city: 'Pune',
    state: 'Maharashtra',
    pincode: '411014',
  );

  late FakeHttpAdapter adapter;
  late ApiHomeRepository repository;

  void answer(ResponseBody Function() reply) {
    adapter = FakeHttpAdapter((_) async => reply());
    repository = ApiHomeRepository(ApiClient(FakeSecureStorage(), _config, adapter: adapter));
  }

  group('featured listings', () {
    test('send only the city and state of the place', () async {
      answer(() => FakeHttpAdapter.ok({'items': <Object>[], 'nearMatch': false}));

      await repository.featuredListings(pune);

      final request = adapter.requests.single;
      expect(request.path, '/home/featured');
      expect(request.queryParameters, {'city': 'Pune', 'state': 'Maharashtra'});
      expect(request.uri.toString(), isNot(contains('411014')));
      expect(request.uri.toString(), isNot(contains('Shivajinagar')));
    });

    test('leave out a state the place does not have', () async {
      answer(() => FakeHttpAdapter.ok({'items': <Object>[]}));

      await repository.featuredListings(const HomeLocation(city: 'Pune'));
      await repository.featuredListings(const HomeLocation(city: 'Pune', state: ''));

      expect(adapter.requests.map((r) => r.queryParameters), [
        {'city': 'Pune'},
        {'city': 'Pune'},
      ]);
    });

    test('become Home cards with price, rating, badge, condition and photo', () async {
      answer(() => FakeHttpAdapter.ok({
            'items': [
              {
                ...listingJson('a',
                    title: 'Sony A7 IV', price: 185000, rating: 4.7, badge: 'BOOSTED'),
                'area': 'Kothrud'
              },
              listingJson('b',
                  title: 'Apple iPhone',
                  condition: 'LIKE_NEW',
                  badge: 'FEATURED',
                  qualifier: 'STARTING_FROM',
                  cardUrl: null),
              listingJson('c', title: 'Flat', condition: null, city: 'Mumbai'),
            ],
            'nearMatch': true,
          }));

      final listings = await repository.featuredListings(pune);

      expect(listings.map((l) => l.id), ['a', 'b', 'c']);
      final first = listings[0];
      expect(first.title, 'Sony A7 IV');
      expect(first.priceInr, 185000);
      expect(first.sellerRating, 4.7);
      expect(first.condition, ListingCondition.good);
      expect(first.isBoosted, isTrue);
      expect(first.isFeatured, isFalse);
      expect(first.city, 'Pune');
      expect(first.area, 'Kothrud');
      expect(first.locationLabel, 'Kothrud, Pune');
      expect(first.image, 'https://media.example/card.jpg');
      final second = listings[1];
      expect(second.condition, ListingCondition.likeNew);
      expect(second.isFeatured, isTrue);
      expect(second.startingFrom, isTrue);
      expect(second.image, isEmpty);
      expect(listings[2].condition, isNull);
      expect(listings[2].city, 'Mumbai');
      expect(listings[2].locationLabel, 'Mumbai');
      expect(listings[2].isBoosted, isFalse);
    });

    test('are empty when the server has nothing to show', () async {
      answer(() => FakeHttpAdapter.ok({
            'items': <Object>[],
            'nearMatch': false,
            'advisory': {'code': 'NO_LISTINGS_NEAR_YOU', 'message': 'No items near you yet'},
          }));

      expect(await repository.featuredListings(pune), isEmpty);
    });

    test('fail with a server error when search is unavailable', () async {
      answer(() => FakeHttpAdapter.error(503, 'ERROR_SEARCH_UNAVAILABLE', 'Search is unavailable'));

      await expectLater(
        repository.featuredListings(pune),
        throwsA(isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.server)),
      );
    });
  });

  group('promos', () {
    test('keep their texts, bundled artwork and in-app target', () async {
      answer(() => FakeHttpAdapter.ok([
            _promoJson(),
            _promoJson(
              id: 'p-2',
              title: 'Chairs',
              imageKey: 'unknown-art',
              target: {'type': 'SEARCH', 'value': 'office chair'},
            ),
            _promoJson(
              id: 'p-3',
              title: 'Pick',
              imageKey: null,
              target: {'type': 'LISTING', 'value': 'listing-9'},
            ),
          ]));

      final promos = await repository.promos();

      expect(adapter.requests.single.path, '/home/promos');
      expect(promos.map((p) => p.id), ['p-1', 'p-2', 'p-3']);
      final first = promos.first;
      expect(first.badge, 'This week');
      expect(first.title, 'Used cars sale');
      expect(first.body, 'Find your next car');
      expect(first.ctaLabel, 'Shop cars');
      expect(first.image, AppAssets.samplePromoImage);
      expect(first.target?.type, PromoTargetType.category);
      expect(first.target?.value, 'L1-CARS');
      expect(promos[1].image, isEmpty);
      expect(promos[1].target?.type, PromoTargetType.search);
      expect(promos[2].image, isEmpty);
      expect(promos[2].target?.type, PromoTargetType.listing);
    });

    test('leave out a promo whose target this app cannot open', () async {
      answer(() => FakeHttpAdapter.ok([
            _promoJson(id: 'p-1'),
            _promoJson(id: 'p-2', target: {'type': 'URL', 'value': 'https://example.com'}),
            _promoJson(id: 'p-3', target: null),
            _promoJson(id: 'p-4', target: {'type': 'CATEGORY'}),
          ]));

      final promos = await repository.promos();

      expect(promos.map((p) => p.id), ['p-1']);
    });

    test('are empty when none is active', () async {
      answer(() => FakeHttpAdapter.ok(<Object>[]));

      expect(await repository.promos(), isEmpty);
    });

    test('fail with a server error when Home cannot load them', () async {
      answer(() => FakeHttpAdapter.error(503, 'ERROR_HOME_LOAD_FAILED', 'Unable to load Home'));

      await expectLater(
        repository.promos(),
        throwsA(isA<ApiError>().having((e) => e.type, 'type', ApiErrorType.server)),
      );
    });
  });

  test('the cart count is zero until the cart exists', () async {
    answer(() => FakeHttpAdapter.ok(<Object>[]));

    final badges = await repository.badges();

    expect(badges.cartItems, 0);
    expect(badges.unreadNotifications, 0);
    expect(adapter.requests, isEmpty);
  });
}
