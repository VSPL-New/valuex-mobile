import 'search_facet.dart';
import 'search_listing.dart';
import 'transaction_intent.dart';

/// One page of results with the facets the server offered for the category (page 0 only).
class SearchPage {
  final List<SearchListing> items;
  final int page;
  final int size;
  final int totalItems;
  final bool hasNext;
  final TransactionIntent? appliedIntent;
  final List<SearchFacet> facets;

  /// `NO_RESULTS_FOUND` when the first page is empty; the app words the message itself.
  final String? advisoryCode;

  const SearchPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.hasNext,
    this.appliedIntent,
    this.facets = const [],
    this.advisoryCode,
  });

  factory SearchPage.fromJson(Map<String, dynamic> json) {
    final advisory = json['advisory'];
    return SearchPage(
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          SearchListing.fromJson(item as Map<String, dynamic>),
      ],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      appliedIntent: TransactionIntent.fromApi(json['appliedIntent'] as String?),
      facets: [
        for (final facet in json['facets'] as List<dynamic>? ?? const [])
          SearchFacet.fromJson(facet as Map<String, dynamic>),
      ],
      advisoryCode: advisory is Map<String, dynamic> ? advisory['code'] as String? : null,
    );
  }
}
