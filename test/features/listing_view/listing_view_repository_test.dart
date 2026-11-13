import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/listing_view/data/listing_view_repository.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockApiClient client;
  late ListingViewRepository repository;

  setUp(() {
    client = MockApiClient();
    repository = ListingViewRepository(client);
  });

  // The mock hands the envelope data to the repository's own parser.
  T Function(Object?) parserOf<T>(Invocation invocation) =>
      invocation.namedArguments[#parse] as T Function(Object?);

  test('view reads the public endpoint of the listing', () async {
    when(() => client.get<PublicListing>(
          '/listings/l1/public',
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<PublicListing>(invocation)({
          'listingId': 'l1',
          'title': 'Apple Watch',
          'seller': {'sellerId': 's1', 'displayName': 'Asha K'},
        }));

    final listing = await repository.view('l1');

    expect(listing.listingId, 'l1');
    expect(listing.seller.displayName, 'Asha K');
  });

  test('seller listings ask for the page and the fixed page size', () async {
    when(() => client.get<SearchPage>(
          '/sellers/s1/listings',
          queryParameters: {'page': 2, 'size': ListingViewRepository.sellerPageSize},
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<SearchPage>(invocation)({
          'items': [
            {'listingId': 'a', 'title': 'Item', 'city': 'Pune'},
          ],
          'page': 2,
          'size': 20,
          'totalItems': 41,
          'hasNext': false,
        }));

    final page = await repository.sellerListings('s1', page: 2);

    expect(page.items.single.id, 'a');
    expect(page.page, 2);
  });

  test('seller reviews report whether reviews exist yet', () async {
    when(() => client.get<SellerReviews>(
          '/sellers/s1/reviews',
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<SellerReviews>(invocation)({
          'reviewsAvailable': false,
          'items': <Object>[],
        }));

    final reviews = await repository.sellerReviews('s1');

    expect(reviews.available, isFalse);
    expect(reviews.count, 0);
  });
}
