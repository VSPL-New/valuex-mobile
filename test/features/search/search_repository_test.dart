import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';
import 'package:valuex_mobile/features/search/domain/search_source.dart';

import 'search_fixtures.dart';

class _CapturingApiClient extends Fake implements ApiClient {
  Map<String, dynamic>? queryParameters;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    this.queryParameters = queryParameters;
    return parse!(pageJson([]));
  }
}

void main() {
  test('sends source only when the caller identifies a voice query', () async {
    final api = _CapturingApiClient();
    final repository = SearchRepository(api);
    const criteria = SearchCriteria(query: 'phone', categoryCode: 'CAT-1');

    await repository.search(criteria);
    expect(api.queryParameters, isNot(contains('source')));
    expect(criteria.toQueryParameters(), isNot(contains('source')));

    await repository.search(criteria, source: SearchSource.voice);
    expect(api.queryParameters, containsPair('source', 'VOICE'));
    expect(api.queryParameters, containsPair('query', 'phone'));
    expect(api.queryParameters, containsPair('category', 'CAT-1'));
  });
}
