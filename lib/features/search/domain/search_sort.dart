/// How results are ordered. [apiValue] is the server's code; relevance is the default.
enum SearchSort {
  relevance('RELEVANCE'),
  newest('NEWEST'),
  priceAsc('PRICE_ASC'),
  priceDesc('PRICE_DESC');

  final String apiValue;

  const SearchSort(this.apiValue);
}
