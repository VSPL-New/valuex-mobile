/// How a category facet is filled in: pick a code, give a range or switch on.
enum FacetType {
  option,
  number,
  boolean;

  static FacetType fromApi(String? value) => switch (value) {
        'NUMBER' => FacetType.number,
        'BOOLEAN' => FacetType.boolean,
        _ => FacetType.option,
      };
}

/// One choice of an option facet with the number of listings it matches.
class FacetBucket {
  final String code;
  final String label;
  final int count;

  const FacetBucket({required this.code, required this.label, required this.count});

  factory FacetBucket.fromJson(Map<String, dynamic> json) => FacetBucket(
        code: json['code'] as String,
        label: json['label'] as String? ?? json['code'] as String,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// A filter the server offers for an L3 category (brand, storage, ...), built from the response.
class SearchFacet {
  final String key;
  final String label;
  final FacetType type;
  final List<FacetBucket> buckets;

  /// The lowest and highest value of a number facet in the current results.
  final num? min;
  final num? max;

  const SearchFacet({
    required this.key,
    required this.label,
    required this.type,
    this.buckets = const [],
    this.min,
    this.max,
  });

  factory SearchFacet.fromJson(Map<String, dynamic> json) => SearchFacet(
        key: json['key'] as String,
        label: json['label'] as String? ?? json['key'] as String,
        type: FacetType.fromApi(json['type'] as String?),
        buckets: [
          for (final bucket in json['buckets'] as List<dynamic>? ?? const [])
            FacetBucket.fromJson(bucket as Map<String, dynamic>),
        ],
        min: json['min'] as num?,
        max: json['max'] as num?,
      );
}
