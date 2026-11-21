/// How the buyer receives a cart line (US-020).
enum DeliveryMode {
  delivery('DELIVERY'),
  selfPickup('SELF_PICKUP');

  final String api;

  const DeliveryMode(this.api);

  static DeliveryMode? fromApi(String? value) {
    for (final mode in values) {
      if (mode.api == value) return mode;
    }
    return null;
  }
}

/// How the buyer pays for a self-pickup line.
enum PaymentOption {
  payNow('PAY_NOW'),
  payAtPickup('PAY_AT_PICKUP');

  final String api;

  const PaymentOption(this.api);

  static PaymentOption? fromApi(String? value) {
    for (final option in values) {
      if (option.api == value) return option;
    }
    return null;
  }
}

/// What the buyer chose for one cart line; every field is null until a choice is saved.
class CartDelivery {
  static const String shippingExceedsPrice = 'SHIPPING_EXCEEDS_PRICE';

  final DeliveryMode? mode;
  final String? addressId;
  final num? shippingCost;
  final DateTime? shippingEta;
  final PaymentOption? paymentOption;

  /// [shippingExceedsPrice] when delivery costs more than the item.
  final String? warning;

  const CartDelivery({
    this.mode,
    this.addressId,
    this.shippingCost,
    this.shippingEta,
    this.paymentOption,
    this.warning,
  });

  static const CartDelivery none = CartDelivery();

  bool get chosen => mode != null;

  factory CartDelivery.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return none;
    final cost = json['shippingCost'];
    final eta = json['shippingEta'];
    return CartDelivery(
      mode: DeliveryMode.fromApi(json['mode'] as String?),
      addressId: json['addressId'] as String?,
      shippingCost: cost == null ? null : num.parse(cost.toString()),
      shippingEta: eta == null ? null : DateTime.parse(eta as String),
      paymentOption: PaymentOption.fromApi(json['paymentOption'] as String?),
      warning: json['warning'] as String?,
    );
  }
}

/// Home delivery as a line allows it. [cost], [etaDate] and [courierName] are set only when the app
/// asked about an address; [reason] is the server's code when [available] is false.
class DeliveryOffer {
  final bool available;
  final String? reason;
  final num? cost;
  final DateTime? etaDate;
  final String? courierName;
  final String? warning;

  const DeliveryOffer({
    required this.available,
    this.reason,
    this.cost,
    this.etaDate,
    this.courierName,
    this.warning,
  });

  bool get exceedsPrice => warning == CartDelivery.shippingExceedsPrice;

  factory DeliveryOffer.fromJson(Map<String, dynamic> json) {
    final cost = json['cost'];
    final eta = json['etaDate'];
    return DeliveryOffer(
      available: json['available'] as bool? ?? false,
      reason: json['reason'] as String?,
      cost: cost == null ? null : num.parse(cost.toString()),
      etaDate: eta == null ? null : DateTime.parse(eta as String),
      courierName: json['courierName'] as String?,
      warning: json['warning'] as String?,
    );
  }
}

/// Where to collect an item: the street line (or area), city, state and pincode; any may be null.
class PickupPlace {
  final String? line1;
  final String? city;
  final String? state;
  final String? pincode;

  const PickupPlace({this.line1, this.city, this.state, this.pincode});

  /// The place on one line, leaving out what is not known.
  String get text => [
        for (final part in [
          line1,
          city,
          [state, pincode].whereType<String>().join(' ')
        ])
          if (part != null && part.trim().isNotEmpty) part.trim(),
      ].join(', ');

  factory PickupPlace.fromJson(Map<String, dynamic> json) => PickupPlace(
        line1: json['line1'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
      );
}

/// Collecting from the seller: the place and who the seller is.
class SelfPickupOffer {
  final bool available;
  final String? reason;
  final PickupPlace? place;
  final String? sellerName;

  const SelfPickupOffer({required this.available, this.reason, this.place, this.sellerName});

  factory SelfPickupOffer.fromJson(Map<String, dynamic> json) {
    final place = json['pickupAddress'];
    return SelfPickupOffer(
      available: json['available'] as bool? ?? false,
      reason: json['reason'] as String?,
      place: place is Map<String, dynamic> ? PickupPlace.fromJson(place) : null,
      sellerName: json['sellerDisplayName'] as String?,
    );
  }
}

/// What a cart line allows for receiving the item, as the server answered.
class DeliveryOptions {
  final String itemId;
  final DeliveryOffer delivery;
  final SelfPickupOffer selfPickup;

  const DeliveryOptions({required this.itemId, required this.delivery, required this.selfPickup});

  factory DeliveryOptions.fromJson(Map<String, dynamic> json) => DeliveryOptions(
        itemId: json['itemId'] as String,
        delivery: DeliveryOffer.fromJson(json['delivery'] as Map<String, dynamic>),
        selfPickup: SelfPickupOffer.fromJson(json['selfPickup'] as Map<String, dynamic>),
      );
}
