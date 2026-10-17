/// A listing plan as the server sends it (US-078). Everything shown about a plan comes from here;
/// nothing in the app depends on a plan code or on a plan being free or paid.
class SellerPlan {
  final String code;
  final String name;
  final double? originalPrice;
  final double price;
  final double discountAmount;
  final int discountPercent;
  final int validityDays;
  final String supportLevel;
  final List<String> features;
  final String? badge;
  final bool recommended;
  final bool priceIncludesGst;
  final double gstRatePercent;
  final double gstAmount;
  final double totalAmount;

  const SellerPlan({
    required this.code,
    required this.name,
    required this.price,
    required this.validityDays,
    required this.supportLevel,
    required this.totalAmount,
    this.originalPrice,
    this.discountAmount = 0,
    this.discountPercent = 0,
    this.features = const [],
    this.badge,
    this.recommended = false,
    this.priceIncludesGst = true,
    this.gstRatePercent = 0,
    this.gstAmount = 0,
  });

  factory SellerPlan.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num).toDouble();
    return SellerPlan(
      code: json['code'] as String,
      name: json['name'] as String,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      price: number('discountedPrice'),
      discountAmount: number('discountAmount'),
      discountPercent: (json['discountPercent'] as num).toInt(),
      validityDays: (json['validityDays'] as num).toInt(),
      supportLevel: json['supportLevel'] as String,
      features: [for (final feature in json['features'] as List<dynamic>) feature as String],
      badge: json['badge'] as String?,
      recommended: json['recommended'] as bool? ?? false,
      priceIncludesGst: json['priceIncludesGst'] as bool? ?? true,
      gstRatePercent: number('gstRatePercent'),
      gstAmount: number('gstAmount'),
      totalAmount: number('totalAmount'),
    );
  }

  bool get isFree => price == 0;

  bool get hasDiscount => originalPrice != null && discountAmount > 0;
}

/// The plan the page starts on and keeps: the seller's choice while it is still in the list,
/// otherwise the one the server marks as recommended, otherwise the first.
SellerPlan? effectivePlan(List<SellerPlan> plans, String? chosenCode) {
  if (plans.isEmpty) return null;
  for (final plan in plans) {
    if (plan.code == chosenCode) return plan;
  }
  for (final plan in plans) {
    if (plan.recommended) return plan;
  }
  return plans.first;
}
