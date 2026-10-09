import '../entities/home_badges.dart';
import '../entities/home_location.dart';
import '../entities/listing.dart';
import '../entities/listing_category.dart';
import '../entities/promo.dart';

/// Content for the Home page. A mock implementation is used until the backend has the endpoints.
abstract class HomeRepository {
  /// All categories, in the order the backend wants them shown.
  Future<List<ListingCategory>> categories();

  /// Active promos only.
  Future<List<Promo>> promos();

  /// Featured and nearby listings, Boosted and Priority first.
  Future<List<Listing>> featuredListings(HomeLocation location);

  Future<HomeBadges> badges();
}
