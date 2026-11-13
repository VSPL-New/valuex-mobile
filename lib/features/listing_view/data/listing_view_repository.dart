import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../search/domain/search_page.dart';
import '../domain/public_listing.dart';

/// What a buyer sees of a listing and its seller (US-012). Everything is read from the server on
/// every open; nothing is taken from the screen that linked here.
class ListingViewRepository {
  static const int sellerPageSize = 20;

  final ApiClient _client;

  ListingViewRepository(this._client);

  Future<PublicListing> view(String listingId) => _client.get(
        ApiConstants.listingPublic(listingId),
        parse: (json) => PublicListing.fromJson(json as Map<String, dynamic>),
      );

  Future<SearchPage> sellerListings(String sellerId, {int page = 0}) => _client.get(
        ApiConstants.sellerListings(sellerId),
        queryParameters: {'page': page, 'size': sellerPageSize},
        parse: (json) => SearchPage.fromJson(json as Map<String, dynamic>),
      );

  Future<SellerReviews> sellerReviews(String sellerId) => _client.get(
        ApiConstants.sellerReviews(sellerId),
        parse: (json) => SellerReviews.fromJson(json as Map<String, dynamic>),
      );
}

final listingViewRepositoryProvider = Provider<ListingViewRepository>(
  (ref) => ListingViewRepository(ref.watch(apiClientProvider)),
);
