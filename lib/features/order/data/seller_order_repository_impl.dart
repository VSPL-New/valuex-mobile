import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/entities/incoming_order.dart';
import '../domain/repositories/seller_order_repository.dart';

/// Calls the four seller order endpoints of the backend (US-112, LLD A.4).
class SellerOrderRepositoryImpl implements SellerOrderRepository {
  final ApiClient _client;

  SellerOrderRepositoryImpl(this._client);

  @override
  Future<IncomingOrdersPage> orders(
      {int page = 0, int size = SellerOrderRepository.pageSize}) async {
    final result = await _client.getPage(
      ApiConstants.sellerOrders,
      queryParameters: {'page': page, 'size': size},
      parseItem: parseIncomingOrder,
    );
    return IncomingOrdersPage(items: result.items, page: result.page, hasMore: result.hasMore);
  }

  @override
  Future<OrdersSummary> summary() => _client.get(
        ApiConstants.sellerOrdersSummary,
        parse: (data) => parseOrdersSummary(data as Map<String, dynamic>),
      );

  @override
  Future<IncomingOrder> startPacking(String orderId) => _client.post(
        ApiConstants.sellerOrderStartPacking(orderId),
        parse: (data) => parseIncomingOrder(data as Map<String, dynamic>),
      );

  @override
  Future<IncomingOrder> markHandedOver(String orderId) => _client.post(
        ApiConstants.sellerOrderHandedOver(orderId),
        parse: (data) => parseIncomingOrder(data as Map<String, dynamic>),
      );
}

/// Reads one card of `GET /seller/orders`. Unknown actions and tags (from a newer backend) are
/// left out, so the card never shows a button the app cannot handle.
IncomingOrder parseIncomingOrder(Map<String, dynamic> json) {
  final item = json['item'] is Map<String, dynamic> ? json['item'] as Map<String, dynamic> : null;
  final buyer =
      json['buyer'] is Map<String, dynamic> ? json['buyer'] as Map<String, dynamic> : null;
  return IncomingOrder(
    id: json['orderId'] as String,
    orderNumber: json['orderNumber'] as String? ?? '',
    bucket: _bucket(json['bucket']),
    orderState: json['orderState'] as String? ?? '',
    tags: [
      for (final value in _list(json['tags']))
        if (_tags[value] != null) _tags[value]!,
    ],
    placedAt: DateTime.tryParse(json['placedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    amount: num.tryParse('${json['amount'] ?? ''}') ?? 0,
    title: item?['title'] as String? ?? '',
    imageUrl: item?['imageUrl'] as String?,
    buyerName: buyer?['displayName'] as String?,
    actions: [
      for (final value in _list(json['actions']))
        if (_actions[value] != null) _actions[value]!,
    ],
    bookingError: json['bookingError'] as String?,
    pickupAddress: _pickupAddress(json['pickupAddress']),
  );
}

OrdersSummary parseOrdersSummary(Map<String, dynamic> json) {
  int read(String key) => (json[key] as num?)?.toInt() ?? 0;
  return OrdersSummary(
    total: read('total'),
    newOrders: read('new'),
    packing: read('packing'),
    scheduled: read('scheduled'),
    shipped: read('shipped'),
  );
}

const Map<String, SellerOrderAction> _actions = {
  'START_PACKING': SellerOrderAction.startPacking,
  'REJECT': SellerOrderAction.reject,
  'CONTINUE_PACKING': SellerOrderAction.continuePacking,
  'SCHEDULE_PICKUP': SellerOrderAction.schedulePickup,
  'VIEW_SCHEDULE': SellerOrderAction.viewSchedule,
  'RESCHEDULE_PICKUP': SellerOrderAction.reschedulePickup,
  'VIEW_PICKUP_DETAILS': SellerOrderAction.viewPickupDetails,
  'MARK_HANDED_OVER': SellerOrderAction.markHandedOver,
};

const Map<String, OrderTag> _tags = {
  'URGENT': OrderTag.urgent,
  'SELF_PICKUP': OrderTag.selfPickup,
  'PICKUP_FAILED': OrderTag.pickupFailed,
  'ARRANGING_PICKUP': OrderTag.arrangingPickup,
  'RETURNING': OrderTag.returning,
  'HANDED_OVER': OrderTag.handedOver,
};

FulfilmentBucket _bucket(Object? value) => switch (value) {
      'PACKING' => FulfilmentBucket.packing,
      'SCHEDULED' => FulfilmentBucket.scheduled,
      'SHIPPED' => FulfilmentBucket.shipped,
      _ => FulfilmentBucket.newOrder,
    };

List<String> _list(Object? value) => value is List<dynamic>
    ? [
        for (final item in value)
          if (item is String) item
      ]
    : const [];

PickupAddress? _pickupAddress(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final line1 = value['line1'] as String?;
  if (line1 == null) return null;
  return PickupAddress(
    line1: line1,
    line2: value['line2'] as String?,
    city: value['city'] as String? ?? '',
    state: value['state'] as String? ?? '',
    pincode: value['pincode'] as String? ?? '',
  );
}
