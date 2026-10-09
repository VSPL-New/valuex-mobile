enum ListingCondition { newItem, likeNew, excellent, good, fair, poor }

/// A listing as shown on a card.
class Listing {
  final String id;
  final String title;

  /// Whole rupees.
  final int priceInr;
  final String city;

  /// 0 to 5, null for a seller without ratings.
  final double? sellerRating;
  final ListingCondition condition;

  /// Paid plan listing (Boosted or Priority).
  final bool isBoosted;

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
  });
}
