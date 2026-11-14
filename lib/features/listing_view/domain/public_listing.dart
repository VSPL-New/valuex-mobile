/// How an action behaves for this listing, as the server decides (US-012).
enum CapabilityReason {
  comingSoon,
  notApplicable,
  ownListing,
  other;

  static CapabilityReason from(String? value) => switch (value) {
        'COMING_SOON' => comingSoon,
        'NOT_APPLICABLE' => notApplicable,
        'OWN_LISTING' => ownListing,
        _ => other,
      };
}

class Capability {
  final bool available;
  final CapabilityReason reason;

  const Capability({required this.available, required this.reason});

  /// Anything the server does not describe is treated as not offered.
  static const Capability missing =
      Capability(available: false, reason: CapabilityReason.notApplicable);

  bool get hidden => !available && reason == CapabilityReason.notApplicable;

  factory Capability.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return missing;
    return Capability(
      available: json['available'] == true,
      reason: CapabilityReason.from(json['reason'] as String?),
    );
  }
}

class Capabilities {
  final Capability chat;
  final Capability call;
  final Capability video;
  final Capability cart;
  final Capability buyNow;

  const Capabilities({
    required this.chat,
    required this.call,
    required this.video,
    required this.cart,
    required this.buyNow,
  });

  factory Capabilities.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return Capabilities(
      chat: Capability.fromJson(map['chat']),
      call: Capability.fromJson(map['call']),
      video: Capability.fromJson(map['video']),
      cart: Capability.fromJson(map['cart']),
      buyNow: Capability.fromJson(map['buyNow']),
    );
  }
}

class ListingPhoto {
  final String mediaId;
  final String thumbnailUrl;
  final String detailUrl;
  final String zoomUrl;

  /// Set only while the links are short-lived signed ones.
  final DateTime? expiresAt;

  const ListingPhoto({
    required this.mediaId,
    required this.thumbnailUrl,
    required this.detailUrl,
    required this.zoomUrl,
    this.expiresAt,
  });

  factory ListingPhoto.fromJson(Map<String, dynamic> json) => ListingPhoto(
        mediaId: json['mediaId'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        detailUrl: json['detailUrl'] as String? ?? '',
        zoomUrl: json['zoomUrl'] as String? ?? '',
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      );
}

/// One schema-labelled attribute; the server already turned option codes into labels.
class ListingAttribute {
  final String key;
  final String label;
  final Object? value;
  final String? unit;

  const ListingAttribute({required this.key, required this.label, this.value, this.unit});

  factory ListingAttribute.fromJson(Map<String, dynamic> json) => ListingAttribute(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'],
        unit: json['unit'] as String?,
      );
}

class ListingSeller {
  final String sellerId;
  final String displayName;

  /// Null until seller ratings exist.
  final double? rating;
  final int ratingCount;
  final String city;
  final String? area;
  final DateTime? joinedAt;
  final int otherListingsCount;

  const ListingSeller({
    required this.sellerId,
    required this.displayName,
    this.rating,
    this.ratingCount = 0,
    this.city = '',
    this.area,
    this.joinedAt,
    this.otherListingsCount = 0,
  });

  factory ListingSeller.fromJson(Map<String, dynamic> json) => ListingSeller(
        sellerId: json['sellerId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble(),
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        city: json['city'] as String? ?? '',
        area: json['area'] as String?,
        joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? ''),
        otherListingsCount: (json['otherListingsCount'] as num?)?.toInt() ?? 0,
      );

  String get locationLabel {
    final locality = area?.trim() ?? '';
    final cityName = city.trim();
    return locality.isEmpty || locality.toLowerCase() == cityName.toLowerCase()
        ? cityName
        : [locality, if (cityName.isNotEmpty) cityName].join(', ');
  }
}

class CategoryStep {
  final String code;
  final String name;

  const CategoryStep({required this.code, required this.name});
}

/// What a buyer may see of a live listing: the response of `GET /listings/{id}/public`.
class PublicListing {
  final String listingId;
  final String title;
  final String description;

  /// The condition code such as `LIKE_NEW`, and the server's English label; null when not applicable.
  final String? conditionCode;
  final String? conditionLabel;
  final String? conditionNotes;
  final num? price;

  /// `STARTING_FROM` when the price is the lowest of a range.
  final String? priceQualifier;
  final bool negotiable;
  final String? transactionIntent;
  final List<CategoryStep> category;
  final List<ListingAttribute> attributes;
  final List<ListingPhoto> photos;
  final ListingSeller seller;
  final DateTime? publishedAt;
  final DateTime? serverTime;
  final Capabilities capabilities;
  final bool ownListing;

  /// The signed-in buyer has saved this listing (US-073); the heart starts from it.
  final bool saved;

  const PublicListing({
    required this.listingId,
    required this.title,
    required this.description,
    required this.seller,
    required this.capabilities,
    this.conditionCode,
    this.conditionLabel,
    this.conditionNotes,
    this.price,
    this.priceQualifier,
    this.negotiable = false,
    this.transactionIntent,
    this.category = const [],
    this.attributes = const [],
    this.photos = const [],
    this.publishedAt,
    this.serverTime,
    this.ownListing = false,
    this.saved = false,
  });

  bool get startingFrom => priceQualifier == 'STARTING_FROM';

  /// Whole days since publication by the server's clock, so the device clock cannot change it.
  int? get ageInDays {
    final published = publishedAt;
    final now = serverTime;
    if (published == null || now == null) return null;
    final days = now.difference(published).inDays;
    return days < 0 ? 0 : days;
  }

  bool get hasExpiringPhotos => photos.any((photo) => photo.expiresAt != null);

  factory PublicListing.fromJson(Map<String, dynamic> json) {
    final condition = json['condition'];
    return PublicListing(
      listingId: json['listingId'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      conditionCode: condition is Map<String, dynamic> ? condition['code'] as String? : null,
      conditionLabel: condition is Map<String, dynamic> ? condition['label'] as String? : null,
      conditionNotes: json['conditionNotes'] as String?,
      price: json['price'] as num?,
      priceQualifier: json['priceQualifier'] as String?,
      negotiable: json['negotiable'] == true,
      transactionIntent: json['transactionIntent'] as String?,
      category: [
        for (final step in json['category'] as List<dynamic>? ?? const [])
          CategoryStep(
            code: (step as Map<String, dynamic>)['code'] as String? ?? '',
            name: step['name'] as String? ?? '',
          ),
      ],
      attributes: [
        for (final item in json['attributes'] as List<dynamic>? ?? const [])
          ListingAttribute.fromJson(item as Map<String, dynamic>),
      ],
      photos: [
        for (final item in json['photos'] as List<dynamic>? ?? const [])
          ListingPhoto.fromJson(item as Map<String, dynamic>),
      ],
      seller: ListingSeller.fromJson(json['seller'] as Map<String, dynamic>? ?? const {}),
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      serverTime: DateTime.tryParse(json['serverTime'] as String? ?? ''),
      capabilities: Capabilities.fromJson(json['capabilities']),
      ownListing: json['ownListing'] == true,
      saved: json['saved'] == true,
    );
  }
}

/// A seller's reviews. Only whether they exist yet is modelled until the rating module is built.
class SellerReviews {
  final bool available;
  final int count;

  const SellerReviews({required this.available, required this.count});

  factory SellerReviews.fromJson(Map<String, dynamic> json) => SellerReviews(
        available: json['reviewsAvailable'] == true,
        count: (json['items'] as List<dynamic>? ?? const []).length,
      );
}
