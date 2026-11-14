import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../search/domain/search_criteria.dart';
import '../domain/saved_search.dart';

/// Saved searches and their daily alert switch (US-066).
class SavedSearchesRepository {
  static const String limitCode = 'ERROR_MAX_SAVED_SEARCHES';
  static const String invalidCriteriaCode = 'ERROR_INVALID_CRITERIA';

  final ApiClient _client;

  SavedSearchesRepository(this._client);

  /// Saves [criteria]; the server names the search when [name] is empty. Throws
  /// [SavedSearchLimitReached] or [SavedSearchInvalidCriteria] for those two refusals.
  Future<SaveResult> create(SearchCriteria criteria, {String? name}) async {
    try {
      final (search, status) = await _client.postWithStatus<SavedSearch>(
        ApiConstants.savedSearches,
        data: {
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          'criteria': savedSearchCriteriaBody(criteria),
        },
        parse: _parse,
      );
      return SaveResult(search, alreadySaved: status == 200);
    } on ApiError catch (error) {
      throw switch (error.code) {
        limitCode => SavedSearchLimitReached(int.tryParse(error.details['max'] ?? '')),
        invalidCriteriaCode => const SavedSearchInvalidCriteria(),
        _ => error,
      };
    }
  }

  Future<List<SavedSearch>> list() => _client.get(
        ApiConstants.savedSearches,
        parse: (json) => [
          for (final entry in json as List<dynamic>)
            SavedSearch.fromJson(entry as Map<String, dynamic>),
        ],
      );

  Future<SavedSearch> setAlerts(String id, {required bool enabled}) => _client.patch(
        ApiConstants.savedSearch(id),
        data: {'alertsEnabled': enabled},
        parse: _parse,
      );

  Future<void> delete(String id) => _client.delete<void>(ApiConstants.savedSearch(id));

  static SavedSearch _parse(Object? json) => SavedSearch.fromJson(json as Map<String, dynamic>);
}

final savedSearchesRepositoryProvider = Provider<SavedSearchesRepository>(
  (ref) => SavedSearchesRepository(ref.watch(apiClientProvider)),
);
