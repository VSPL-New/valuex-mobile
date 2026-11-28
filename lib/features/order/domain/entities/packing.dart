import 'incoming_order.dart';

/// The two photo sections of Pack & Upload Proof (US-026).
enum ProofKind {
  /// The item before packing ("Item Photos").
  itemCondition('ITEM_CONDITION'),

  /// The packed and sealed item ("Packaging Photos").
  packageSealed('PACKAGE_SEALED');

  final String wire;

  const ProofKind(this.wire);
}

/// One photo the server has attached to the packing. [url] is a short-lived link, null when the
/// server could not make one just now.
class OrderProof {
  final String id;
  final ProofKind kind;
  final String? url;
  final DateTime uploadedAt;
  final bool submitted;

  const OrderProof({
    required this.id,
    required this.kind,
    this.url,
    required this.uploadedAt,
    this.submitted = false,
  });
}

/// The packed weight in kg and size in cm a courier needs (LLD C.4.1).
class PackageSize {
  static const double minWeightKg = 0.05;
  static const double maxWeightKg = 30;
  static const double minSideCm = 1;
  static const double maxSideCm = 150;

  final double weightKg;
  final double lengthCm;
  final double breadthCm;
  final double heightCm;

  const PackageSize({
    required this.weightKg,
    required this.lengthCm,
    required this.breadthCm,
    required this.heightCm,
  });

  static bool validWeight(double? kg) => kg != null && kg >= minWeightKg && kg <= maxWeightKg;

  static bool validSide(double? cm) => cm != null && cm >= minSideCm && cm <= maxSideCm;
}

/// The photo counts per section and the clear-photo minimum, set by Admin (plan G10).
class PackingRules {
  final int itemMin;
  final int itemMax;
  final int packageMin;
  final int packageMax;
  final int minPixels;

  const PackingRules({
    this.itemMin = 2,
    this.itemMax = 4,
    this.packageMin = 1,
    this.packageMax = 2,
    this.minPixels = 480,
  });

  int min(ProofKind kind) => kind == ProofKind.itemCondition ? itemMin : packageMin;

  int max(ProofKind kind) => kind == ProofKind.itemCondition ? itemMax : packageMax;
}

/// Everything Pack & Upload Proof shows: the order, the photos so far, the packed size already
/// confirmed (null until then) and the rules.
class PackingView {
  final IncomingOrder order;
  final List<OrderProof> proofs;
  final PackageSize? packageSize;
  final PackingRules rules;

  const PackingView({
    required this.order,
    this.proofs = const [],
    this.packageSize,
    this.rules = const PackingRules(),
  });

  PackingView copyWith({List<OrderProof>? proofs}) => PackingView(
      order: order, proofs: proofs ?? this.proofs, packageSize: packageSize, rules: rules);

  List<OrderProof> of(ProofKind kind) => [
        for (final proof in proofs)
          if (proof.kind == kind) proof,
      ];
}
