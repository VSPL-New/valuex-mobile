/// The four groups of the seller's Incoming Orders, in page order (US-112).
enum FulfilmentBucket { newOrder, packing, scheduled, shipped }

/// A button on an Incoming Orders card. The server decides which apply, so the app holds no order
/// state machine.
enum SellerOrderAction {
  startPacking,
  reject,
  continuePacking,
  schedulePickup,
  viewSchedule,
  reschedulePickup,
  viewPickupDetails,
  markHandedOver,
}

/// An extra label on a card, decided by the server.
enum OrderTag { urgent, selfPickup, pickupFailed, arrangingPickup, returning, handedOver }

/// The seller's pickup address on a self-pickup order, as the buyer sees it.
class PickupAddress {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;

  const PickupAddress({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
  });

  /// The lines to show, one per row.
  List<String> get lines => [
        line1,
        if (line2 != null && line2!.trim().isNotEmpty) line2!,
        '$city, $state $pincode',
      ];
}

/// One order placed on one of the seller's items.
class IncomingOrder {
  final String id;
  final String orderNumber;
  final FulfilmentBucket bucket;
  final String orderState;
  final List<OrderTag> tags;
  final DateTime placedAt;
  final num amount;
  final String title;
  final String? imageUrl;
  final String? buyerName;
  final List<SellerOrderAction> actions;

  /// Why the courier could not be booked, while the seller must schedule again.
  final String? bookingError;
  final PickupAddress? pickupAddress;

  const IncomingOrder({
    required this.id,
    required this.orderNumber,
    required this.bucket,
    required this.orderState,
    this.tags = const [],
    required this.placedAt,
    required this.amount,
    required this.title,
    this.imageUrl,
    this.buyerName,
    this.actions = const [],
    this.bookingError,
    this.pickupAddress,
  });

  bool has(OrderTag tag) => tags.contains(tag);
}

/// The counts behind the header line, the "{x} New" badge and the four tiles.
class OrdersSummary {
  final int total;
  final int newOrders;
  final int packing;
  final int scheduled;
  final int shipped;

  const OrdersSummary({
    this.total = 0,
    this.newOrders = 0,
    this.packing = 0,
    this.scheduled = 0,
    this.shipped = 0,
  });

  int count(FulfilmentBucket bucket) => switch (bucket) {
        FulfilmentBucket.newOrder => newOrders,
        FulfilmentBucket.packing => packing,
        FulfilmentBucket.scheduled => scheduled,
        FulfilmentBucket.shipped => shipped,
      };
}

/// One page of the list.
class IncomingOrdersPage {
  final List<IncomingOrder> items;
  final int page;
  final bool hasMore;

  const IncomingOrdersPage({required this.items, required this.page, required this.hasMore});
}
