import 'package:flutter/foundation.dart';
import '../../search/domain/search_criteria.dart';
import '../../search/domain/transaction_intent.dart';

/// The request body names that are never saved: the sort, the Home place hint and the voice
/// marker. A saved search is what the buyer asked for, not how it was asked or ordered.
const Set<String> _neverSaved = {'sort', 'source', 'nearCity', 'nearState'};

/// True when there is something to save: text, a category or a filter. The "See All" browse and
/// a Real Estate category still waiting for Buy, Rent or Lease are not saved yet.
bool canSaveSearch(SearchCriteria criteria) =>
    (criteria.trimmedQuery.isNotEmpty || criteria.categoryCode != null || criteria.hasFilters) &&
    !criteria.needsIntent;

/// The `criteria` object of `POST /search/saved`: the search request fields of
/// [SearchCriteria.toQueryParameters] without the sort (and never the source or near place).
Map<String, dynamic> savedSearchCriteriaBody(SearchCriteria criteria) => {
      for (final entry in criteria.toQueryParameters().entries)
        if (!_neverSaved.contains(entry.key)) entry.key: entry.value,
    };

/// A search the buyer saved (US-066): its criteria, the daily alert switch and whether the
/// category and filters still exist.
@immutable
class SavedSearch {
  final String id;
  final String name;

  /// What to search for; category name, level and Real Estate flag are filled from the list
  /// response so the results page can be rebuilt without another request.
  final SearchCriteria criteria;
  final bool alertsEnabled;

  /// False when the category was disabled or removed, or a filter no longer exists.
  final bool valid;
  final String? invalidMessage;
  final DateTime? lastAlertAt;
  final DateTime? createdAt;

  const SavedSearch({
    required this.id,
    required this.name,
    required this.criteria,
    required this.alertsEnabled,
    this.valid = true,
    this.invalidMessage,
    this.lastAlertAt,
    this.createdAt,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    final stored = json['criteria'] as Map<String, dynamic>? ?? const {};
    final level = (json['categoryLevel'] as num?)?.toInt();
    return SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      criteria: SearchCriteria(
        query: stored['query'] as String? ?? '',
        categoryCode: stored['category'] as String?,
        categoryName: json['categoryName'] as String?,
        categoryLevel: level,
        realEstate: json['realEstate'] as bool? ?? false,
        intent: TransactionIntent.fromApi(stored['transactionIntent'] as String?),
        priceMin: double.tryParse('${stored['priceMin'] ?? ''}'),
        priceMax: double.tryParse('${stored['priceMax'] ?? ''}'),
        conditions: {for (final code in stored['condition'] as List<dynamic>? ?? const []) '$code'},
        state: stored['state'] as String?,
        city: stored['city'] as String?,
        facets: _facets(stored['facet'] as List<dynamic>? ?? const []),
      ),
      alertsEnabled: json['alertsEnabled'] as bool? ?? true,
      valid: json['valid'] as bool? ?? true,
      invalidMessage: json['invalidMessage'] as String?,
      lastAlertAt: _date(json['lastAlertAt']),
      createdAt: _date(json['createdAt']),
    );
  }

  /// `key:value` entries split on the first colon, so a value such as `32..128` stays whole.
  static Map<String, String> _facets(List<dynamic> entries) {
    final facets = <String, String>{};
    for (final entry in entries) {
      final text = '$entry';
      final colon = text.indexOf(':');
      if (colon > 0) facets[text.substring(0, colon)] = text.substring(colon + 1);
    }
    return facets;
  }

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;

  SavedSearch copyWith({bool? alertsEnabled}) => SavedSearch(
        id: id,
        name: name,
        criteria: criteria,
        alertsEnabled: alertsEnabled ?? this.alertsEnabled,
        valid: valid,
        invalidMessage: invalidMessage,
        lastAlertAt: lastAlertAt,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      other is SavedSearch &&
      other.id == id &&
      other.name == name &&
      other.criteria == criteria &&
      other.alertsEnabled == alertsEnabled &&
      other.valid == valid &&
      other.invalidMessage == invalidMessage &&
      other.lastAlertAt == lastAlertAt &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        criteria,
        alertsEnabled,
        valid,
        invalidMessage,
        lastAlertAt,
        createdAt,
      );
}

/// What saving a search did: [alreadySaved] when the server returned the existing search.
class SaveResult {
  final SavedSearch search;
  final bool alreadySaved;

  const SaveResult(this.search, {required this.alreadySaved});
}

/// The account is at the Admin-set maximum (`ERROR_MAX_SAVED_SEARCHES`).
class SavedSearchLimitReached implements Exception {
  /// How many searches are allowed; null when the server did not say.
  final int? max;

  const SavedSearchLimitReached([this.max]);

  @override
  String toString() => 'SavedSearchLimitReached(max: $max)';
}

/// The criteria are empty or not accepted by search any more (`ERROR_INVALID_CRITERIA`).
class SavedSearchInvalidCriteria implements Exception {
  const SavedSearchInvalidCriteria();

  @override
  String toString() => 'SavedSearchInvalidCriteria()';
}
