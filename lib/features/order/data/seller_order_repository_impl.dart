import 'dart:typed_data';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../listing/data/listing_repository.dart';
import '../domain/entities/incoming_order.dart';
import '../domain/entities/packing.dart';
import '../domain/repositories/seller_order_repository.dart';

/// Calls the seller order endpoints of the backend: Incoming Orders (US-112, LLD A.4) and Pack &
/// Upload Proof (US-026, LLD D.3).
class SellerOrderRepositoryImpl implements SellerOrderRepository {
  final ApiClient _client;
  final ListingRepository _uploads;

  SellerOrderRepositoryImpl(this._client, this._uploads);

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

  @override
  Future<PackingView> packing(String orderId) => _client.get(
        ApiConstants.sellerOrderPacking(orderId),
        parse: (data) => parsePackingView(data as Map<String, dynamic>),
      );

  @override
  Future<String> uploadProofPhoto({
    required String ownerId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
    required int width,
    required int height,
  }) async {
    final ticket = await _client.post<UploadTicket>(
      ApiConstants.mediaUploads,
      data: {
        'purpose': 'SELLER_PRE_SHIPMENT_EVIDENCE',
        'ownerType': 'USER',
        'ownerId': ownerId,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': bytes.length,
      },
      parse: (json) {
        final map = json as Map<String, dynamic>;
        return UploadTicket(
            mediaId: map['mediaId'] as String, uploadUrl: map['uploadUrl'] as String);
      },
    );
    await _uploads.uploadBytes(ticket.uploadUrl, bytes, contentType);
    await _uploads.completeUpload(
      mediaId: ticket.mediaId,
      contentType: contentType,
      sizeBytes: bytes.length,
      width: width,
      height: height,
    );
    return ticket.mediaId;
  }

  @override
  Future<OrderProof> attachProof(String orderId, String mediaId, ProofKind kind) => _client.post(
        ApiConstants.sellerOrderPackingProofs(orderId),
        data: {'mediaId': mediaId, 'kind': kind.wire},
        parse: (data) => parseOrderProof(data as Map<String, dynamic>)!,
      );

  @override
  Future<void> removeProof(String orderId, String proofId) =>
      _client.delete<void>(ApiConstants.sellerOrderPackingProof(orderId, proofId));

  @override
  Future<IncomingOrder> completePacking(String orderId, PackageSize size) => _client.post(
        ApiConstants.sellerOrderPackingComplete(orderId),
        data: {
          'package': {
            'weightKg': size.weightKg,
            'lengthCm': size.lengthCm,
            'breadthCm': size.breadthCm,
            'heightCm': size.heightCm,
          },
        },
        parse: (data) => parseIncomingOrder(data as Map<String, dynamic>),
      );
}

/// Reads `GET /seller/orders/{id}/packing`. A photo of a kind this app does not know is left out.
PackingView parsePackingView(Map<String, dynamic> json) {
  final rules =
      json['rules'] is Map<String, dynamic> ? json['rules'] as Map<String, dynamic> : null;
  final size = json['packageSize'] is Map<String, dynamic>
      ? json['packageSize'] as Map<String, dynamic>
      : null;
  const defaults = PackingRules();
  int rule(String key, int fallback) => (rules?[key] as num?)?.toInt() ?? fallback;
  return PackingView(
    order: parseIncomingOrder(json['order'] as Map<String, dynamic>),
    proofs: [
      for (final value
          in json['proofs'] is List<dynamic> ? json['proofs'] as List<dynamic> : const [])
        if (value is Map<String, dynamic>)
          if (parseOrderProof(value) case final proof?) proof,
    ],
    packageSize: size == null ? null : _packageSize(size),
    rules: PackingRules(
      itemMin: rule('itemMin', defaults.itemMin),
      itemMax: rule('itemMax', defaults.itemMax),
      packageMin: rule('packageMin', defaults.packageMin),
      packageMax: rule('packageMax', defaults.packageMax),
      minPixels: rule('minPixels', defaults.minPixels),
    ),
  );
}

/// One packing photo; null for a kind this app does not know.
OrderProof? parseOrderProof(Map<String, dynamic> json) {
  final kind = ProofKind.values.where((k) => k.wire == json['kind']).firstOrNull;
  if (kind == null) return null;
  return OrderProof(
    id: json['proofId'] as String,
    kind: kind,
    url: json['url'] as String?,
    uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    submitted: json['submitted'] as bool? ?? false,
  );
}

PackageSize? _packageSize(Map<String, dynamic> json) {
  double? read(String key) => num.tryParse('${json[key] ?? ''}')?.toDouble();
  final weight = read('weightKg');
  final length = read('lengthCm');
  final breadth = read('breadthCm');
  final height = read('heightCm');
  if (weight == null || length == null || breadth == null || height == null) return null;
  return PackageSize(weightKg: weight, lengthCm: length, breadthCm: breadth, heightCm: height);
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
