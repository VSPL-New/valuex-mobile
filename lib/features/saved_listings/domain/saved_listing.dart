import 'package:flutter/foundation.dart';

/// Why a saved listing cannot be bought now. [underReview] is temporary (the listing is hidden for
/// a check or is in negotiation); the others are permanent.
enum UnavailableReason {
  sold,
  expired,
  removed,
  deleted,
  sellerSuspended,
  underReview;

  static UnavailableReason? fromApi(String? value) => switch (value) {
        'SOLD' => UnavailableReason.sold,
        'EXPIRED' => UnavailableReason.expired,
        'REMOVED' => UnavailableReason.removed,
        'DELETED' => UnavailableReason.deleted,
        'SELLER_SUSPENDED' => UnavailableReason.sellerSuspended,
        'UNDER_REVIEW' => UnavailableReason.underReview,
        _ => null,
      };
}

/// One row of Saved Items (US-073). Title and price are always the listing's current ones.
@immutable
class SavedListing {
  final String id;
  final String title;
  final num? price;

  /// A condition code such as `LIKE_NEW`; null when the listing has none.
  final String? condition;

  /// Null for an unavailable listing: it carries no photo.
  final String? thumbnailUrl;
  final bool available;
  final UnavailableReason? reason;
  final DateTime? savedAt;

  const SavedListing({
    required this.id,
    required this.title,
    this.price,
    this.condition,
    this.thumbnailUrl,
    this.available = true,
    this.reason,
    this.savedAt,
  });

  factory SavedListing.fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    final available = json['available'] != false;
    return SavedListing(
      id: json['listingId'] as String,
      title: json['title'] as String? ?? '',
      price: json['price'] as num?,
      condition: json['condition'] as String?,
      thumbnailUrl: photo is Map<String, dynamic> ? photo['thumbnailUrl'] as String? : null,
      available: available,
      reason: available ? null : UnavailableReason.fromApi(json['unavailableReason'] as String?),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
    );
  }
}

/// One page of Saved Items.
@immutable
class SavedListingsPage {
  final List<SavedListing> items;
  final int page;
  final bool hasNext;
  final int totalItems;

  /// The limit per buyer; null when the server did not say.
  final int? maxSaved;

  const SavedListingsPage({
    required this.items,
    required this.page,
    required this.hasNext,
    required this.totalItems,
    this.maxSaved,
  });

  factory SavedListingsPage.fromJson(Map<String, dynamic> json) => SavedListingsPage(
        items: [
          for (final item in json['items'] as List<dynamic>? ?? const [])
            SavedListing.fromJson(item as Map<String, dynamic>),
        ],
        page: (json['page'] as num?)?.toInt() ?? 0,
        hasNext: json['hasNext'] == true,
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
        maxSaved: (json['maxSaved'] as num?)?.toInt(),
      );
}

/// The server refused a save because the buyer is at the limit.
class SavedListingLimitReached implements Exception {
  final int? max;

  const SavedListingLimitReached(this.max);
}

/// The server refused a save because the listing is no longer live.
class SavedListingUnavailable implements Exception {
  const SavedListingUnavailable();
}
