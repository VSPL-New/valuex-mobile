// My Listings (US-010): the seller's own listings with the counts shown above them.

/// Which listings My Listings shows. [apiValue] is what the server filters by; All sends none.
enum MyListingsFilter {
  all,
  active,
  sold;

  String? get apiValue => switch (this) {
        MyListingsFilter.all => null,
        MyListingsFilter.active => 'ACTIVE',
        MyListingsFilter.sold => 'SOLD',
      };
}

/// How a property deal ended (US-118); [apiValue] is the server's code. Each belongs to one intent:
/// sold to Buy, rented to Rent, leased to Lease.
enum ClosedOutcome {
  sold('SOLD'),
  rented('RENTED'),
  leased('LEASED');

  final String apiValue;

  const ClosedOutcome(this.apiValue);

  static ClosedOutcome? fromApi(String? value) {
    for (final outcome in values) {
      if (outcome.apiValue == value) return outcome;
    }
    return null;
  }
}

/// How a listing's server status reads to the seller on its card.
enum ListingBadge {
  active,
  sold,
  draft,
  processingPayment,
  underReview,
  needsChanges,
  expired,
  rejected,
  unavailable;

  static ListingBadge forStatus(String status) => switch (status) {
        'PUBLISHED' => ListingBadge.active,
        'SOLD' => ListingBadge.sold,
        'DRAFT' || 'PLAN_SELECTION_PENDING' || 'PLAN_PAYMENT_FAILED' => ListingBadge.draft,
        'PLAN_PAYMENT_PENDING' || 'PLAN_PAYMENT_SUCCESS' => ListingBadge.processingPayment,
        'TRUST_SAFETY_REVIEW' || 'APPROVED' => ListingBadge.underReview,
        'REVISION_REQUIRED' => ListingBadge.needsChanges,
        'EXPIRED' => ListingBadge.expired,
        'REJECTED' => ListingBadge.rejected,
        _ => ListingBadge.unavailable,
      };
}

class MyListingsSummary {
  /// Every listing that is not deleted.
  final int total;

  /// Published listings only.
  final int active;
  final int sold;

  /// Zero until views are tracked (US-067).
  final int totalViews;

  const MyListingsSummary({
    this.total = 0,
    this.active = 0,
    this.sold = 0,
    this.totalViews = 0,
  });

  factory MyListingsSummary.fromJson(Map<String, dynamic> json) => MyListingsSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        active: (json['active'] as num?)?.toInt() ?? 0,
        sold: (json['sold'] as num?)?.toInt() ?? 0,
        totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      );
}

/// One listing card.
class MyListingItem {
  final String id;

  /// Empty for a draft that has no title yet.
  final String title;
  final num? price;

  /// The server's status, for example `PUBLISHED` or `TRUST_SAFETY_REVIEW`.
  final String status;
  final String? planName;
  final int viewCount;
  final int chatCount;

  /// A short-lived link to the main photo; null when the listing has none.
  final String? thumbnailUrl;
  final bool canEdit;
  final bool canDelete;

  /// How the owner can close this published property (Sold, Rented or Leased); null when the
  /// server does not offer it, which is always so for goods (US-118).
  final ClosedOutcome? closeOutcome;

  /// How a closed property ended, so a rented one does not read as sold; null otherwise.
  final ClosedOutcome? closedOutcome;

  const MyListingItem({
    required this.id,
    required this.status,
    this.title = '',
    this.price,
    this.planName,
    this.viewCount = 0,
    this.chatCount = 0,
    this.thumbnailUrl,
    this.canEdit = false,
    this.canDelete = false,
    this.closeOutcome,
    this.closedOutcome,
  });

  factory MyListingItem.fromJson(Map<String, dynamic> json) => MyListingItem(
        id: json['id'] as String,
        status: json['status'] as String? ?? '',
        title: json['title'] as String? ?? '',
        price: json['price'] as num?,
        planName: json['planName'] as String?,
        viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
        chatCount: (json['chatCount'] as num?)?.toInt() ?? 0,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        canEdit: json['canEdit'] as bool? ?? false,
        canDelete: json['canDelete'] as bool? ?? false,
        closeOutcome: ClosedOutcome.fromApi(json['closeOutcome'] as String?),
        closedOutcome: ClosedOutcome.fromApi(json['closedOutcome'] as String?),
      );

  ListingBadge get badge => ListingBadge.forStatus(status);
  bool get isSold => status == 'SOLD';
}

class MyListingsPage {
  final MyListingsSummary summary;
  final List<MyListingItem> items;
  final int page;
  final bool hasNext;

  const MyListingsPage({
    this.summary = const MyListingsSummary(),
    this.items = const [],
    this.page = 0,
    this.hasNext = false,
  });

  factory MyListingsPage.fromJson(Map<String, dynamic> json) => MyListingsPage(
        summary: MyListingsSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? const {}),
        items: [
          for (final item in json['items'] as List<dynamic>? ?? const [])
            MyListingItem.fromJson(item as Map<String, dynamic>),
        ],
        page: (json['page'] as num?)?.toInt() ?? 0,
        hasNext: json['hasNext'] as bool? ?? false,
      );
}
