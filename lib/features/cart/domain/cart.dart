/// Where one cart line stands, decided by the server on every read (US-019). Only [accepted] can be
/// bought; [pending] is an offer still waiting for the seller.
enum CartLineStatus {
  accepted,
  pending,
  expired,
  unavailable;

  static CartLineStatus fromApi(String? value) => switch (value) {
        'ACCEPTED' => accepted,
        'PENDING' => pending,
        'UNAVAILABLE' => unavailable,
        _ => expired,
      };

  bool get payable => this == accepted;
}

/// One item in the cart. [agreedPrice] is the price the buyer agreed; [currentPrice] is what the
/// listing asks now (null when the listing is gone). [problem] is the server's error code for a line
/// that cannot be bought, and [agreementValidUntil] is set only for an accepted line.
class CartLine {
  final String itemId;
  final String listingId;
  final String? title;
  final String? imageUrl;
  final num agreedPrice;
  final num? currentPrice;
  final CartLineStatus status;
  final DateTime? agreementValidUntil;
  final DateTime addedAt;
  final DateTime expiresAt;
  final String? problem;

  const CartLine({
    required this.itemId,
    required this.listingId,
    required this.title,
    required this.imageUrl,
    required this.agreedPrice,
    required this.currentPrice,
    required this.status,
    required this.agreementValidUntil,
    required this.addedAt,
    required this.expiresAt,
    required this.problem,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        itemId: json['itemId'] as String,
        listingId: json['listingId'] as String,
        title: json['title'] as String?,
        imageUrl: json['imageUrl'] as String?,
        agreedPrice: num.parse(json['agreedPrice'].toString()),
        currentPrice:
            json['currentPrice'] == null ? null : num.parse(json['currentPrice'].toString()),
        status: CartLineStatus.fromApi(json['status'] as String?),
        agreementValidUntil: json['agreementValidUntil'] == null
            ? null
            : DateTime.parse(json['agreementValidUntil'] as String),
        addedAt: DateTime.parse(json['addedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        problem: json['problem'] as String?,
      );
}

/// The lines of one seller. [sellerName] is null when the seller has no display name.
class CartGroup {
  final String sellerId;
  final String? sellerName;
  final List<CartLine> items;

  const CartGroup({required this.sellerId, required this.sellerName, required this.items});

  factory CartGroup.fromJson(Map<String, dynamic> json) => CartGroup(
        sellerId: json['sellerId'] as String,
        sellerName: json['sellerName'] as String?,
        items: [
          for (final item in json['items'] as List<dynamic>)
            CartLine.fromJson(item as Map<String, dynamic>),
        ],
      );
}

/// The cart as the server answered. [serverTime] is the server's clock when it answered, so the
/// countdown on each line does not depend on the phone's clock.
class CartData {
  final String? cartId;
  final DateTime serverTime;
  final int itemCount;
  final int validCount;
  final List<CartGroup> groups;

  const CartData({
    required this.cartId,
    required this.serverTime,
    required this.itemCount,
    required this.validCount,
    required this.groups,
  });

  bool get isEmpty => itemCount == 0;

  /// The total of the lines that can be bought now, at their agreed prices.
  num get payableTotal => [
        for (final group in groups)
          for (final line in group.items)
            if (line.status.payable) line.agreedPrice,
      ].fold<num>(0, (sum, price) => sum + price);

  factory CartData.fromJson(Map<String, dynamic> json) => CartData(
        cartId: json['cartId'] as String?,
        serverTime: DateTime.parse(json['serverTime'] as String),
        itemCount: (json['itemCount'] as num).toInt(),
        validCount: (json['validCount'] as num).toInt(),
        groups: [
          for (final group in json['groups'] as List<dynamic>)
            CartGroup.fromJson(group as Map<String, dynamic>),
        ],
      );
}

/// The numbers behind the cart badge on Home.
class CartSummary {
  final int itemCount;
  final int validCount;

  const CartSummary({required this.itemCount, required this.validCount});

  factory CartSummary.fromJson(Map<String, dynamic> json) => CartSummary(
        itemCount: (json['itemCount'] as num).toInt(),
        validCount: (json['validCount'] as num).toInt(),
      );
}
