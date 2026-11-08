import 'category.dart';
import 'existing_listing.dart';
import 'listing_details.dart';
import 'listing_schema.dart';

/// A short-lived link to one photo (`POST /media/{id}/access`).
class PhotoLink {
  final String url;
  final DateTime? expiresAt;

  const PhotoLink({required this.url, this.expiresAt});

  factory PhotoLink.fromJson(Map<String, dynamic> json) => PhotoLink(
        url: json['accessUrl'] as String,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      );
}

/// What the owner's read-only preview shows (US-123): the saved listing as `GET /listings/{id}`
/// returns it, plus the review reason, plan name, publication date and the category's form.
///
/// Values stay as saved: a missing quantity is null, not the editor's default of 1.
class ListingPreviewData {
  final String listingId;
  final String status;
  final List<ListingImageRef> images;
  final String title;
  final CategoryRef? category;
  final ListingCondition? condition;
  final String conditionNotes;
  final String description;
  final num? price;
  final bool? negotiable;
  final int? quantity;
  final Map<String, Object?> attributes;
  final String city;

  /// Null when the category's form could not be built; the screen then says so.
  final ListingSchema? schema;
  final String? reviewReason;
  final String? planName;
  final DateTime? publishedAt;

  const ListingPreviewData({
    required this.listingId,
    required this.status,
    this.images = const [],
    this.title = '',
    this.category,
    this.condition,
    this.conditionNotes = '',
    this.description = '',
    this.price,
    this.negotiable,
    this.quantity,
    this.attributes = const {},
    this.city = '',
    this.schema,
    this.reviewReason,
    this.planName,
    this.publishedAt,
  });

  factory ListingPreviewData.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final attributes = json['attributes'];
    final schema = json['listingSchema'];
    return ListingPreviewData(
      listingId: json['listingId'] as String,
      status: json['status'] as String? ?? '',
      images: [
        for (final image in json['images'] as List<dynamic>? ?? const [])
          ListingImageRef.fromJson(image as Map<String, dynamic>),
      ],
      title: json['title'] as String? ?? '',
      category: category is Map<String, dynamic> ? CategoryRef.fromJson(category) : null,
      condition: ListingCondition.fromApi(json['condition'] as String?),
      conditionNotes: json['conditionNotes'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as num?,
      negotiable: json['negotiable'] as bool?,
      quantity: (json['quantity'] as num?)?.toInt(),
      attributes: attributes is Map<String, dynamic> ? {...attributes} : const {},
      city: json['location'] as String? ?? '',
      schema: schema is Map<String, dynamic> ? ListingSchema.fromJson(schema) : null,
      reviewReason: _blankToNull(json['reviewReason'] as String?),
      planName: _blankToNull(json['planName'] as String?),
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    );
  }

  /// The plan badge appears only once the listing has been live (decided with US-123).
  String? get planBadge => publishedAt == null ? null : planName;

  static String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
