import 'l3_category_artwork.g.dart';

/// Single place for asset paths. To rebrand, replace the files these point to.
class AppAssets {
  AppAssets._();

  static const String logo = 'assets/images/logo.png';
  static const String createAccountIllustration = 'assets/images/create_account_illustration.png';

  static const String arrowRightIcon = 'assets/icons/arrow_right.svg';
  static const String backButtonFrameIcon = 'assets/icons/back_button_frame.svg';
  static const String backChevronIcon = 'assets/icons/back_chevron.svg';
  static const String googleIcon = 'assets/icons/google.svg';
  static const String guestIcon = 'assets/icons/guest_person_voice.svg';

  static const String _categoryArtwork = 'assets/images/categories/l1';
  static const int categoryArtworkPixelSize = 256;
  static const Map<String, String> l3CategoryArtwork = l3CategoryArtworkByCode;
  static const Map<String, String> l1CategoryArtwork = {
    'L1-MOBILES_TABLETS': '$_categoryArtwork/mobiles.webp',
    'L1-COMPUTERS_IT': '$_categoryArtwork/computers.webp',
    'L1-CAMERAS_PHOTOGRAPHY': '$_categoryArtwork/cameras.webp',
    'L1-CARS': '$_categoryArtwork/cars.webp',
    'L1-FURNITURE': '$_categoryArtwork/furniture.webp',
    'L1-TV_AUDIO_HOME_ENTERTAINMENT': '$_categoryArtwork/tv-audio.webp',
    'L1-GAMING': '$_categoryArtwork/gaming.webp',
    'L1-LARGE_APPLIANCES': '$_categoryArtwork/large-appliances.webp',
    'L1-SMALL_HOME_APPLIANCES': '$_categoryArtwork/small-appliances.webp',
    'L1-HOME_DECOR_FURNISHINGS': '$_categoryArtwork/home-decor.webp',
    'L1-KITCHEN_DINING': '$_categoryArtwork/kitchen.webp',
    'L1-HOME_IMPROVEMENT_TOOLS': '$_categoryArtwork/tools.webp',
    'L1-GARDEN_OUTDOOR': '$_categoryArtwork/garden.webp',
    'L1-MEN_S_FASHION': '$_categoryArtwork/mens-fashion.webp',
    'L1-WOMEN_S_FASHION': '$_categoryArtwork/womens-fashion.webp',
    'L1-KIDS_BABY_CLOTHING': '$_categoryArtwork/kids-clothing.webp',
    'L1-FOOTWEAR': '$_categoryArtwork/footwear.webp',
    'L1-BAGS_WALLETS_LUGGAGE': '$_categoryArtwork/bags.webp',
    'L1-WATCHES_JEWELLERY_FASHION_ACCESSORIES': '$_categoryArtwork/watches-jewellery.webp',
    'L1-BEAUTY_PERSONAL_CARE': '$_categoryArtwork/beauty.webp',
    'L1-BABY_GEAR_NURSERY': '$_categoryArtwork/baby-gear.webp',
    'L1-TOYS_GAMES': '$_categoryArtwork/toys.webp',
    'L1-BOOKS_STATIONERY_EDUCATION': '$_categoryArtwork/books.webp',
    'L1-SPORTS_FITNESS_OUTDOOR': '$_categoryArtwork/sports.webp',
    'L1-MUSICAL_INSTRUMENTS_PRO_AUDIO': '$_categoryArtwork/music.webp',
    'L1-MOTORCYCLES_SCOOTERS': '$_categoryArtwork/motorcycles.webp',
    'L1-COMMERCIAL_AGRICULTURAL_VEHICLES': '$_categoryArtwork/commercial-vehicles.webp',
    'L1-VEHICLE_PARTS_ACCESSORIES': '$_categoryArtwork/vehicle-parts.webp',
    'L1-BICYCLES_MICRO_MOBILITY': '$_categoryArtwork/bicycles.webp',
    'L1-OFFICE_BUSINESS_EQUIPMENT': '$_categoryArtwork/office.webp',
    'L1-INDUSTRIAL_COMMERCIAL_EQUIPMENT': '$_categoryArtwork/industrial.webp',
    'L1-HEALTH_MEDICAL_EQUIPMENT': '$_categoryArtwork/health.webp',
    'L1-PET_SUPPLIES': '$_categoryArtwork/pets.webp',
    'L1-ART_ANTIQUES_COLLECTIBLES': '$_categoryArtwork/antiques.webp',
    'L1-ARTS_CRAFTS_HOBBY_SUPPLIES': '$_categoryArtwork/crafts.webp',
    'L1-RELIGIOUS_FESTIVE_PARTY': '$_categoryArtwork/festive.webp',
    'L1-PACKAGED_GROCERY_CONSUMABLES_OPTIONAL': '$_categoryArtwork/grocery.webp',
    'L1-OTHER': '$_categoryArtwork/other.webp',
    'L1-REAL_ESTATE': '$_categoryArtwork/real-estate.webp',
  };

  static const Map<String, String> homeCategoryArtworkCodes = {
    'electronics': 'L1-TV_AUDIO_HOME_ENTERTAINMENT',
    'laptops': 'L1-COMPUTERS_IT',
    'mobiles': 'L1-MOBILES_TABLETS',
    'cameras': 'L1-CAMERAS_PHOTOGRAPHY',
    'vehicles': 'L1-CARS',
    'furniture': 'L1-FURNITURE',
    'fashion': 'L1-MEN_S_FASHION',
    'appliances': 'L1-SMALL_HOME_APPLIANCES',
    'books': 'L1-BOOKS_STATIONERY_EDUCATION',
    'sports': 'L1-SPORTS_FITNESS_OUTDOOR',
    'toys': 'L1-TOYS_GAMES',
    'music': 'L1-MUSICAL_INSTRUMENTS_PRO_AUDIO',
  };

  // Home header, search and cards
  static const String homeSearchIcon = 'assets/icons/home_search.svg';
  static const String homeCameraIcon = 'assets/icons/home_camera.svg';
  static const String homeMoreIcon = 'assets/icons/home_more.svg';
  static const String homeStarIcon = 'assets/icons/home_star.svg';
  static const String homePromoPattern = 'assets/icons/home_promo_pattern.svg';
  static const String homeLocationPinIcon = 'assets/icons/home_location_pin.svg';
  static const String homeChevronDownIcon = 'assets/icons/home_chevron_down.svg';
  static const String homeCartIcon = 'assets/icons/home_cart.svg';
  static const String homeBellIcon = 'assets/icons/home_bell.svg';

  // Bottom navigation
  static const String navHomeIcon = 'assets/icons/nav_home.svg';
  static const String navSearchIcon = 'assets/icons/nav_search.svg';
  static const String navSellIcon = 'assets/icons/nav_sell.svg';
  static const String navChatsIcon = 'assets/icons/nav_chats.svg';
  static const String navProfileIcon = 'assets/icons/nav_profile.svg';

  // Sample content until the backend supplies it
  static const String samplePromoImage = 'assets/images/home_promo_1.png';

  /// Bundled promo artwork by the `imageKey` a promo row carries. A key not listed here shows the
  /// neutral placeholder, so a promo with new artwork waits for an app release that bundles it.
  static const Map<String, String> promoArtwork = {'home_promo_1': samplePromoImage};

  static const String sampleCategoryElectronic = 'assets/images/home_cat_electronic.png';
  static const String sampleCategoryLaptops = 'assets/images/home_cat_laptops.png';
  static const String sampleCategoryMobiles = 'assets/images/home_cat_mobiles.png';
  static const String sampleCategoryCameras = 'assets/images/home_cat_cameras.png';
  static const String sampleCategoryVehicles = 'assets/images/home_cat_vehicles.png';
  static const String sampleListingWatch = 'assets/images/home_listing_watch.jpg';
  static const String sampleListingChair = 'assets/images/home_listing_chair.jpg';
  static const String sampleListingDrone = 'assets/images/home_listing_drone.jpg';
  static const String sampleListingBike = 'assets/images/home_listing_bike.jpg';
  static const String sampleListingIpad = 'assets/images/home_listing_ipad.jpg';
}
