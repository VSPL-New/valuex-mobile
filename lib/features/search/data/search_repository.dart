import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/search_criteria.dart';
import '../domain/search_page.dart';
import '../domain/search_suggestion.dart';

/// Search over the published listings (US-011). Only the city and state of the Home place go
/// along, to rank nearby listings first; coordinates are never sent.
class SearchRepository {
  static const int pageSize = 20;
  static const int defaultSuggestionLimit = 8;

  final ApiClient _client;

  SearchRepository(this._client);

  /// One page of results. Facets are asked for with the first page of an L3 category.
  Future<SearchPage> search(
    SearchCriteria criteria, {
    int page = 0,
    int size = pageSize,
    String? nearCity,
    String? nearState,
  }) =>
      _client.get(
        ApiConstants.searchListings,
        queryParameters: {
          ...criteria.toQueryParameters(),
          'page': page,
          'size': size,
          if (page == 0 && criteria.isLeafCategory) 'includeFacets': true,
          if (nearCity != null && nearCity.isNotEmpty) 'nearCity': nearCity,
          if (nearState != null && nearState.isNotEmpty) 'nearState': nearState,
        },
        parse: (json) => SearchPage.fromJson(json as Map<String, dynamic>),
      );

  /// Auto-complete entries for the text typed so far: up to three categories, then listing
  /// titles. An entry this app cannot show is left out.
  Future<List<SearchSuggestion>> suggest(String query, {int limit = defaultSuggestionLimit}) =>
      _client.get(
        ApiConstants.searchSuggestions,
        queryParameters: {'query': query, 'limit': limit},
        parse: (json) => [
          for (final entry in json as List<dynamic>)
            if (SearchSuggestion.tryParse(entry) case final suggestion?) suggestion,
        ],
      );
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(apiClientProvider)),
);
