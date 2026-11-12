import 'package:flutter/foundation.dart';
import 'search_sort.dart';
import 'transaction_intent.dart';

const Object _unset = Object();

/// Everything the buyer asked for: text, category, intent, filters and sort. Immutable, with
/// value equality, so it can also describe a saved search (US-066). The place used to rank
/// nearby listings is not part of it: that is context, not something the buyer chose here.
@immutable
class SearchCriteria {
  /// The server accepts at most this many characters of search text.
  static const int maxQueryLength = 200;

  final String query;
  final String? categoryCode;
  final String? categoryName;

  /// 1, 2 or 3. Facets exist only for an L3 category.
  final int? categoryLevel;

  /// The category is under Real Estate, so Buy, Rent or Lease must be chosen before searching.
  final bool realEstate;

  /// Show everything, ranked for the buyer's place ("See All" on Home), without text or category.
  final bool browseAll;
  final TransactionIntent? intent;
  final double? priceMin;
  final double? priceMax;

  /// Condition codes such as `GOOD`.
  final Set<String> conditions;
  final String? state;
  final String? city;

  /// Facet key to the value in the server's grammar: an option code, `min..max` or `true`.
  final Map<String, String> facets;
  final SearchSort sort;

  const SearchCriteria({
    this.query = '',
    this.categoryCode,
    this.categoryName,
    this.categoryLevel,
    this.realEstate = false,
    this.browseAll = false,
    this.intent,
    this.priceMin,
    this.priceMax,
    this.conditions = const {},
    this.state,
    this.city,
    this.facets = const {},
    this.sort = SearchSort.relevance,
  });

  String get trimmedQuery => query.trim();

  bool get hasPriceRange => priceMin != null || priceMax != null;

  bool get hasFilters =>
      hasPriceRange || conditions.isNotEmpty || state != null || city != null || facets.isNotEmpty;

  /// How many filter groups are on, for the badge on the filter button.
  int get filterCount =>
      (hasPriceRange ? 1 : 0) +
      (conditions.isNotEmpty ? 1 : 0) +
      (state != null ? 1 : 0) +
      (city != null ? 1 : 0) +
      facets.length;

  /// Nothing was asked for yet, so the start page shows instead of results.
  bool get isBlank => trimmedQuery.isEmpty && categoryCode == null && !browseAll && !hasFilters;

  bool get isLeafCategory => categoryLevel == 3;

  bool get needsIntent => realEstate && intent == null;

  /// Condition filters are not valid for Real Estate.
  bool get allowsConditions => !realEstate;

  SearchCriteria copyWith({
    String? query,
    Object? categoryCode = _unset,
    Object? categoryName = _unset,
    Object? categoryLevel = _unset,
    bool? realEstate,
    bool? browseAll,
    Object? intent = _unset,
    Object? priceMin = _unset,
    Object? priceMax = _unset,
    Set<String>? conditions,
    Object? state = _unset,
    Object? city = _unset,
    Map<String, String>? facets,
    SearchSort? sort,
  }) {
    return SearchCriteria(
      query: query ?? this.query,
      categoryCode: identical(categoryCode, _unset) ? this.categoryCode : categoryCode as String?,
      categoryName: identical(categoryName, _unset) ? this.categoryName : categoryName as String?,
      categoryLevel: identical(categoryLevel, _unset) ? this.categoryLevel : categoryLevel as int?,
      realEstate: realEstate ?? this.realEstate,
      browseAll: browseAll ?? this.browseAll,
      intent: identical(intent, _unset) ? this.intent : intent as TransactionIntent?,
      priceMin: identical(priceMin, _unset) ? this.priceMin : (priceMin as num?)?.toDouble(),
      priceMax: identical(priceMax, _unset) ? this.priceMax : (priceMax as num?)?.toDouble(),
      conditions: conditions ?? this.conditions,
      state: identical(state, _unset) ? this.state : state as String?,
      city: identical(city, _unset) ? this.city : city as String?,
      facets: facets ?? this.facets,
      sort: sort ?? this.sort,
    );
  }

  /// Drops the price, condition, place and facet filters; text, category, intent and sort stay.
  SearchCriteria withoutFilters() => copyWith(
        priceMin: null,
        priceMax: null,
        conditions: const {},
        state: null,
        city: null,
        facets: const {},
      );

  /// The request parameters of `GET /search/listings`, without paging and the near place.
  Map<String, dynamic> toQueryParameters() {
    final text = trimmedQuery;
    return {
      if (text.isNotEmpty) 'query': text,
      if (categoryCode != null) 'category': categoryCode,
      if (intent != null) 'transactionIntent': intent!.apiValue,
      if (priceMin != null) 'priceMin': formatPrice(priceMin!),
      if (priceMax != null) 'priceMax': formatPrice(priceMax!),
      if (conditions.isNotEmpty) 'condition': conditions.toList()..sort(),
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (facets.isNotEmpty)
        'facet': [for (final entry in facets.entries) '${entry.key}:${entry.value}'],
      if (sort != SearchSort.relevance) 'sort': sort.apiValue,
    };
  }

  /// Two decimals at most, as the server requires, so paise are not lost.
  static String formatPrice(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
  }

  @override
  bool operator ==(Object other) =>
      other is SearchCriteria &&
      other.query == query &&
      other.categoryCode == categoryCode &&
      other.categoryName == categoryName &&
      other.categoryLevel == categoryLevel &&
      other.realEstate == realEstate &&
      other.browseAll == browseAll &&
      other.intent == intent &&
      other.priceMin == priceMin &&
      other.priceMax == priceMax &&
      setEquals(other.conditions, conditions) &&
      other.state == state &&
      other.city == city &&
      mapEquals(other.facets, facets) &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
        query,
        categoryCode,
        categoryName,
        categoryLevel,
        realEstate,
        browseAll,
        intent,
        priceMin,
        priceMax,
        Object.hashAllUnordered(conditions),
        state,
        city,
        Object.hashAllUnordered(facets.entries.map((e) => Object.hash(e.key, e.value))),
        sort,
      );
}
