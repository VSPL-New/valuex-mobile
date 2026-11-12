enum ListingCondition { newItem, likeNew, excellent, good, fair, poor }

/// A listing as shown on a card.
class Listing {
  final String id;
  final String title;

  /// Rupees, with paise when the price has them; null when the listing shows no price.
  final num? priceInr;
  final String city;

  /// 0 to 5, null for a seller without ratings.
  final double? sellerRating;

  /// Null for a listing without a condition, such as a property.
  final ListingCondition? condition;

  /// Paid plan listing (Boosted or Priority).
  final bool isBoosted;

  /// Top paid plan: the "Featured" badge.
  final bool isFeatured;

  /// The price is the lowest of a range, so the card says "Starting from".
  final bool startingFrom;

  /// Asset path (sample data) or network URL.
  final String image;

  const Listing({
    required this.id,
    required this.title,
    required this.priceInr,
    required this.city,
    required this.condition,
    required this.image,
    this.sellerRating,
    this.isBoosted = false,
    this.isFeatured = false,
    this.startingFrom = false,
  });
}
