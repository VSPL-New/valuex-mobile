import '../../../../core/constants/app_assets.dart';
import '../domain/entities/home_badges.dart';
import '../domain/entities/home_location.dart';
import '../domain/entities/listing.dart';
import '../domain/entities/promo.dart';
import '../domain/repositories/home_repository.dart';

/// Sample promos, featured listings and cart counts; categories use the real taxonomy.
class MockHomeRepository implements HomeRepository {
  const MockHomeRepository();

  @override
  Future<List<Promo>> promos() async => const [
        Promo(
          id: 'sample-ai-photo-search',
          badge: '24 hours only',
          title: 'Unlock AI Photo Search',
          body: 'Find instantly what you\u2019re looking for',
          ctaLabel: 'Claim Voucher',
          image: AppAssets.samplePromoImage,
        ),
      ];

  @override
  Future<List<Listing>> featuredListings(HomeLocation location) async => const [
        Listing(
          id: 'sony-a7-iv',
          title: 'Sony A7 IV Camera',
          priceInr: 185000,
          city: 'Delhi',
          sellerRating: 4.7,
          condition: ListingCondition.good,
          isBoosted: true,
          image: AppAssets.sampleCategoryCameras,
        ),
        Listing(
          id: 'galaxy-watch-6',
          title: 'Samsung Galaxy Watch 6',
          priceInr: 22000,
          city: 'Pune',
          sellerRating: 4.6,
          condition: ListingCondition.likeNew,
          image: AppAssets.sampleListingWatch,
        ),
        Listing(
          id: 'aeron-chair',
          title: 'Herman Miller Aeron Chair',
          priceInr: 45000,
          city: 'Hyderabad',
          sellerRating: 4.5,
          condition: ListingCondition.excellent,
          isBoosted: true,
          image: AppAssets.sampleListingChair,
        ),
        Listing(
          id: 'dji-mini-4-pro',
          title: 'DJI Mini 4 Pro Drone',
          priceInr: 62000,
          city: 'Chennai',
          sellerRating: 4.9,
          condition: ListingCondition.likeNew,
          image: AppAssets.sampleListingDrone,
        ),
        Listing(
          id: 'royal-enfield-350',
          title: 'Royal Enfield Classic 350',
          priceInr: 120000,
          city: 'Jaipur',
          sellerRating: 4.4,
          condition: ListingCondition.good,
          image: AppAssets.sampleListingBike,
        ),
        Listing(
          id: 'ipad-pro-m2',
          title: 'iPad Pro 12.9" M2',
          priceInr: 74000,
          city: 'Kolkata',
          sellerRating: 4.8,
          condition: ListingCondition.likeNew,
          image: AppAssets.sampleListingIpad,
        ),
      ];

  @override
  Future<HomeBadges> badges() async => const HomeBadges(cartItems: 2);
}
