import 'category.dart';
import 'listing_details.dart';

/// A photo already on a listing: the listing image id (to remove it) and its media asset (to show it).
class ListingImageRef {
  final String imageId;
  final String mediaId;
  final int sortOrder;

  const ListingImageRef({required this.imageId, required this.mediaId, required this.sortOrder});

  factory ListingImageRef.fromJson(Map<String, dynamic> json) => ListingImageRef(
        imageId: json['imageId'] as String,
        mediaId: json['mediaId'] as String,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

/// A listing the seller already created, as the server stores it (`GET /listings/{id}`); used to
/// reopen Item Details or plan selection from a notification.
class ExistingListing {
  final String listingId;

  /// The server's listing status, for example `REVISION_REQUIRED` or `PLAN_PAYMENT_FAILED`.
  final String status;
  final ListingDetailsDraft draft;
  final CategoryRef? category;
  final String city;

  /// The photos in order; the first is the main photo.
  final List<ListingImageRef> images;

  const ExistingListing({
    required this.listingId,
    required this.status,
    required this.draft,
    this.category,
    this.city = '',
    this.images = const [],
  });

  factory ExistingListing.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final categoryRef = category is Map<String, dynamic> ? CategoryRef.fromJson(category) : null;
    final attributes = json['attributes'];
    return ExistingListing(
      listingId: json['listingId'] as String,
      status: json['status'] as String? ?? '',
      category: categoryRef,
      city: json['location'] as String? ?? '',
      images: [
        for (final image in json['images'] as List<dynamic>? ?? const [])
          ListingImageRef.fromJson(image as Map<String, dynamic>),
      ],
      draft: ListingDetailsDraft(
        title: json['title'] as String? ?? '',
        categoryCode: categoryRef?.code,
        condition: ListingCondition.fromApi(json['condition'] as String?),
        conditionNotes: json['conditionNotes'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: _priceText(json['price']),
        negotiable: json['negotiable'] as bool?,
        quantity: ((json['quantity'] as num?)?.toInt() ?? 1).toString(),
        attributes: attributes is Map<String, dynamic> ? {...attributes} : const {},
      ),
    );
  }

  /// "1200" for whole rupees, "49.50" otherwise, the way the seller types it.
  static String _priceText(Object? value) {
    if (value is! num) return '';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
  }
}
