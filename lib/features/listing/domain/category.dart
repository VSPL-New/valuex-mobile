/// Which categories to list under a parent (US-006): the popular ones first, then the rest.
enum CategoryScope {
  popular('POPULAR'),
  others('OTHERS'),
  all('ALL');

  final String apiValue;

  const CategoryScope(this.apiValue);
}

/// One category in a browse list. Only L3 (a leaf) can be chosen for a listing.
class CategoryNode {
  final String code;
  final String name;
  final int level;
  final bool hasChildren;
  final bool popular;
  final String marketplaceStatus;

  const CategoryNode({
    required this.code,
    required this.name,
    required this.level,
    required this.hasChildren,
    this.popular = false,
    this.marketplaceStatus = 'ALLOWED',
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) => CategoryNode(
        code: json['code'] as String,
        name: json['name'] as String,
        level: json['level'] as int,
        hasChildren: json['hasChildren'] as bool? ?? false,
        popular: json['popular'] as bool? ?? false,
        marketplaceStatus: json['marketplaceStatus'] as String? ?? 'ALLOWED',
      );
}

class CategoryPathItem {
  final String code;
  final String name;
  final int level;

  const CategoryPathItem({required this.code, required this.name, required this.level});

  factory CategoryPathItem.fromJson(Map<String, dynamic> json) => CategoryPathItem(
        code: json['code'] as String,
        name: json['name'] as String,
        level: json['level'] as int,
      );
}

/// An L3 category with its L1 and L2 ancestors, as chosen for a listing.
class CategoryRef {
  final String code;
  final String name;
  final String marketplaceStatus;
  final List<CategoryPathItem> path;

  const CategoryRef({
    required this.code,
    required this.name,
    this.marketplaceStatus = 'ALLOWED',
    this.path = const [],
  });

  factory CategoryRef.fromJson(Map<String, dynamic> json) => CategoryRef(
        code: json['code'] as String,
        name: json['name'] as String,
        marketplaceStatus: json['marketplaceStatus'] as String? ?? 'ALLOWED',
        path: [
          for (final item in json['path'] as List<dynamic>? ?? const [])
            CategoryPathItem.fromJson(item as Map<String, dynamic>),
        ],
      );

  /// The ancestors without the category itself, for example "Mobiles & Tablets > Smartphones".
  String get parentsLabel =>
      path.where((item) => item.level < 3).map((item) => item.name).join(' > ');
}
