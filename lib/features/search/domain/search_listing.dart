import 'transaction_intent.dart';

/// Marks a paid-plan listing.
enum SearchBadge {
  boosted,
  featured;

  static SearchBadge? fromApi(String? value) => switch (value) {
        'BOOSTED' => SearchBadge.boosted,
        'FEATURED' => SearchBadge.featured,
        _ => null,
      };
}

/// One result card. Prices are decimal rupees, so paise are kept.
class SearchListing {
  final String id;
  final String title;
  final num? price;

  /// `STARTING_FROM` when the price is the lowest of a range, otherwise null.
  final String? priceQualifier;
  final TransactionIntent? transactionIntent;
  final String city;
  final String? area;

  /// A condition code such as `LIKE_NEW`; null for Real Estate.
  final String? condition;
  final double? sellerRating;
  final SearchBadge? badge;
  final String? thumbnailUrl;
  final String? cardUrl;
  final DateTime? publishedAt;
  final String? categoryName;
  final bool saved;

  const SearchListing({
    required this.id,
    required this.title,
    required this.city,
    this.area,
    this.price,
    this.priceQualifier,
    this.transactionIntent,
    this.condition,
    this.sellerRating,
    this.badge,
    this.thumbnailUrl,
    this.cardUrl,
    this.publishedAt,
    this.categoryName,
    this.saved = false,
  });

  bool get startingFrom => priceQualifier == 'STARTING_FROM';

  factory SearchListing.fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    final category = json['category'];
    return SearchListing(
      id: json['listingId'] as String,
      title: json['title'] as String,
      price: json['price'] as num?,
      priceQualifier: json['priceQualifier'] as String?,
      transactionIntent: TransactionIntent.fromApi(json['transactionIntent'] as String?),
      city: json['city'] as String? ?? '',
      area: json['area'] as String?,
      condition: json['condition'] as String?,
      sellerRating: (json['sellerRating'] as num?)?.toDouble(),
      badge: SearchBadge.fromApi(json['badge'] as String?),
      thumbnailUrl: photo is Map<String, dynamic> ? photo['thumbnailUrl'] as String? : null,
      cardUrl: photo is Map<String, dynamic> ? photo['cardUrl'] as String? : null,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      categoryName: category is Map<String, dynamic> ? category['l3Name'] as String? : null,
      saved: json['saved'] as bool? ?? false,
    );
  }
}
