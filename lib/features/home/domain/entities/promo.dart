/// A promo card. The product team supplies the content; the app only renders it.
class Promo {
  final String id;
  final String badge;
  final String title;
  final String body;
  final String ctaLabel;

  /// Asset path (sample data) or network URL.
  final String image;

  const Promo({
    required this.id,
    required this.badge,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.image,
  });
}
