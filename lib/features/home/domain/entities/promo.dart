/// Where a promo leads. Always inside the app, so a promo never opens an outside site.
enum PromoTargetType {
  category,
  search,
  listing;

  static PromoTargetType? fromApi(String? value) => switch (value) {
        'CATEGORY' => category,
        'SEARCH' => search,
        'LISTING' => listing,
        _ => null,
      };
}

class PromoTarget {
  final PromoTargetType type;

  /// A category code, a search text or a listing id, by [type].
  final String value;

  const PromoTarget({required this.type, required this.value});
}

/// A promo card. The product team supplies the content; the app only renders it.
class Promo {
  final String id;
  final String badge;
  final String title;
  final String body;
  final String ctaLabel;

  /// Asset path (sample data) or network URL.
  final String image;

  /// Null for sample data, which opens nothing.
  final PromoTarget? target;

  const Promo({
    required this.id,
    required this.badge,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.image,
    this.target,
  });
}
