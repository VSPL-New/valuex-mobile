import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/saved_searches/data/saved_searches_repository.dart';
import 'package:valuex_mobile/features/saved_searches/domain/saved_search.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';

/// The JSON of one saved search as `GET /search/saved` returns it.
Map<String, dynamic> savedSearchJson(
  String id, {
  String name = 'Phones in Pune',
  bool alerts = true,
  bool valid = true,
  Map<String, dynamic>? criteria,
  String? categoryName = 'Smartphones',
  int? categoryLevel = 3,
  bool realEstate = false,
}) =>
    {
      'id': id,
      'name': name,
      'criteria': criteria ??
          {
            'query': 'iphone',
            'category': 'CAT-1',
            'facet': ['brand:apple', 'storage_gb:32..128'],
            'priceMin': '100',
            'priceMax': '900.5',
            'condition': ['GOOD', 'NEW'],
            'city': 'Pune',
            'state': 'Maharashtra',
          },
      'alertsEnabled': alerts,
      'valid': valid,
      'invalidMessage': valid ? null : 'Search criteria no longer valid',
      'lastAlertAt': '2026-11-13T04:30:00Z',
      'createdAt': '2026-11-10T09:00:00Z',
      'categoryName': categoryName,
      'categoryLevel': categoryLevel,
      'realEstate': realEstate,
    };

/// A saved-searches repository whose answers a test decides.
class FakeSavedSearchesRepository extends Fake implements SavedSearchesRepository {
  Future<List<SavedSearch>> Function() onList = () async => const [];
  Future<SaveResult> Function(SearchCriteria criteria) onCreate =
      (criteria) async => throw StateError('create not set');
  Future<SavedSearch> Function(String id, bool enabled) onSetAlerts =
      (id, enabled) async => throw StateError('setAlerts not set');
  Future<void> Function(String id) onDelete = (id) async {};

  int listCalls = 0;
  final List<SearchCriteria> created = [];
  final List<(String, bool)> alertCalls = [];
  final List<String> deleted = [];

  @override
  Future<List<SavedSearch>> list() {
    listCalls++;
    return onList();
  }

  @override
  Future<SaveResult> create(SearchCriteria criteria, {String? name}) {
    created.add(criteria);
    return onCreate(criteria);
  }

  @override
  Future<SavedSearch> setAlerts(String id, {required bool enabled}) {
    alertCalls.add((id, enabled));
    return onSetAlerts(id, enabled);
  }

  @override
  Future<void> delete(String id) {
    deleted.add(id);
    return onDelete(id);
  }
}
