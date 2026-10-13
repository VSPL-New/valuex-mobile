import '../../../../core/constants/app_assets.dart';
import '../domain/entities/home_badges.dart';
import '../domain/entities/home_location.dart';
import '../domain/entities/listing.dart';
import '../domain/entities/listing_category.dart';
import '../domain/entities/promo.dart';
import '../domain/repositories/home_repository.dart';

/// Sample content standing in for the backend, which has no category, listing or promo
/// endpoints yet. Replace with a repository that calls the API.
class MockHomeRepository implements HomeRepository {
  const MockHomeRepository();

  @override
  Future<List<ListingCategory>> categories() async => const [
        ListingCategory(
          id: 'electronics',
          name: 'Electronic',
          image: AppAssets.sampleCategoryElectronic,
        ),
        ListingCategory(id: 'laptops', name: 'Laptops', image: AppAssets.sampleCategoryLaptops),
        ListingCategory(id: 'mobiles', name: 'Mobiles', image: AppAssets.sampleCategoryMobiles),
        ListingCategory(id: 'cameras', name: 'Cameras', image: AppAssets.sampleCategoryCameras),
        ListingCategory(id: 'vehicles', name: 'Vehicles', image: AppAssets.sampleCategoryVehicles),
        ListingCategory(id: 'furniture', name: 'Furniture'),
        ListingCategory(id: 'fashion', name: 'Fashion'),
        ListingCategory(id: 'appliances', name: 'Home Appliances'),
        ListingCategory(id: 'books', name: 'Books'),
        ListingCategory(id: 'sports', name: 'Sports'),
        ListingCategory(id: 'toys', name: 'Toys'),
        ListingCategory(id: 'music', name: 'Musical Instruments'),
      ];

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
