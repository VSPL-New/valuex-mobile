class ListingCategory {
  final String id;
  final String name;

  /// Asset path (sample data) or network URL; null shows a neutral placeholder.
  final String? image;

  const ListingCategory({required this.id, required this.name, this.image});
}
