import 'package:dio/dio.dart';

/// One page of a paged list: its items, where it sits in the full list and the response headers.
class ApiPage<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final Headers headers;

  const ApiPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.headers,
  });

  bool get hasMore => page + 1 < totalPages;
}
