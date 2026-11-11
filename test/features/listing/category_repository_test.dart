import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/constants/api_constants.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';

import '../../helpers/mocks.dart';

void main() {
  test('category tree requests are public and preserve parent and scope', () async {
    final client = MockApiClient();
    final storage = Dio();
    addTearDown(storage.close);
    final repository = ListingRepository(client, storage);
    const nodes = [
      CategoryNode(code: 'CAT-0001', name: 'Smartphones', level: 3, hasChildren: false),
    ];
    when(() => client.get<List<CategoryNode>>(
          ApiConstants.categoryChildren,
          authenticated: false,
          queryParameters: any(named: 'queryParameters'),
          parse: any(named: 'parse'),
        )).thenAnswer((_) async => nodes);

    expect(await repository.categoryChildren(parentCode: 'L2-PHONES'), nodes);
    expect(await repository.categoryChildren(scope: CategoryScope.popular), nodes);
    verify(() => client.get<List<CategoryNode>>(
          ApiConstants.categoryChildren,
          authenticated: false,
          queryParameters: {'parentCode': 'L2-PHONES', 'scope': 'ALL'},
          parse: any(named: 'parse'),
        )).called(1);
    verify(() => client.get<List<CategoryNode>>(
          ApiConstants.categoryChildren,
          authenticated: false,
          queryParameters: {'scope': 'POPULAR'},
          parse: any(named: 'parse'),
        )).called(1);
  });
}
