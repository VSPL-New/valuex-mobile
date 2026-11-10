import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> listingJson(
  String id, {
  String title = 'Apple iPhone 14 128GB',
  num? price = 42000.00,
  String? qualifier,
  String? intent,
  String city = 'Pune',
  String? condition = 'GOOD',
  num? rating,
  String? badge,
  String? cardUrl = 'https://media.example/card.jpg',
}) =>
    {
      'listingId': id,
      'title': title,
      'price': price,
      'priceQualifier': qualifier,
      'transactionIntent': intent,
      'city': city,
      'condition': condition,
      'sellerRating': rating,
      'badge': badge,
      'photo': cardUrl == null
          ? null
          : {'thumbnailUrl': 'https://media.example/thumb.jpg', 'cardUrl': cardUrl},
      'publishedAt': '2026-11-09T09:00:00Z',
      'category': {'l3Code': 'CAT-0001', 'l3Name': 'Smartphones'},
      'saved': false,
    };

const facetsJson = [
  {
    'key': 'brand',
    'label': 'Brand',
    'type': 'OPTION',
    'buckets': [
      {'code': 'apple', 'label': 'Apple', 'count': 41},
      {'code': 'samsung', 'label': 'Samsung', 'count': 12},
    ],
  },
  {'key': 'storage_gb', 'label': 'Storage', 'type': 'NUMBER', 'min': 16, 'max': 512},
  {'key': 'dual_sim', 'label': 'Dual SIM', 'type': 'BOOLEAN'},
];

Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> items, {
  int page = 0,
  int? total,
  bool hasNext = false,
  List<Map<String, dynamic>>? facets,
  String? advisory,
  String? appliedIntent,
}) =>
    {
      'items': items,
      'page': page,
      'size': 20,
      'totalItems': total ?? items.length,
      'hasNext': hasNext,
      'appliedIntent': appliedIntent,
      if (facets != null) 'facets': facets,
      'advisory': advisory == null ? null : {'code': advisory, 'message': 'No items found'},
    };

/// A page of [count] listings whose ids run on from [start].
SearchPage listingsPage(int start, int count,
        {int total = 100, bool hasNext = true, int page = 0}) =>
    SearchPage.fromJson(
      pageJson(
        [for (var i = start; i < start + count; i++) listingJson('l$i', title: 'Item $i')],
        page: page,
        total: total,
        hasNext: hasNext,
      ),
    );

class SearchCall {
  final SearchCriteria criteria;
  final int page;
  final String? nearCity;
  final String? nearState;

  const SearchCall(this.criteria, this.page, this.nearCity, this.nearState);
}

typedef SearchHandler = Future<SearchPage> Function(SearchCriteria criteria, int page);

/// A search repository whose answers a test decides, which records what was asked.
class FakeSearchRepository extends Fake implements SearchRepository {
  SearchHandler handler;
  final List<SearchCall> calls = [];

  FakeSearchRepository(this.handler);

  @override
  Future<SearchPage> search(
    SearchCriteria criteria, {
    int page = 0,
    int size = SearchRepository.pageSize,
    String? nearCity,
    String? nearState,
  }) {
    calls.add(SearchCall(criteria, page, nearCity, nearState));
    return handler(criteria, page);
  }
}
