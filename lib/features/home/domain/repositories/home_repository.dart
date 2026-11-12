import '../entities/home_badges.dart';
import '../entities/home_location.dart';
import '../entities/listing.dart';
import '../entities/promo.dart';

/// Non-category Home content. Categories use the shared listing taxonomy repository.
abstract class HomeRepository {
  /// Active promos only.
  Future<List<Promo>> promos();

  /// Featured and nearby listings, Boosted and Priority first.
  Future<List<Listing>> featuredListings(HomeLocation location);

  Future<HomeBadges> badges();
}
