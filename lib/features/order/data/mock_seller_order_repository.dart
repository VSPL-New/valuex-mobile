import 'dart:typed_data';

import '../../../core/network/api_error.dart';
import '../domain/entities/incoming_order.dart';
import '../domain/entities/packing.dart';
import '../domain/repositories/seller_order_repository.dart';

/// The four sample orders of the Figma Make `SellerIncomingOrdersScreen`, one per group, for demos
/// and QA before checkout creates real orders (US-112, `SELLER_ORDERS=mock`). Photos are left out
/// (the card shows its placeholder); Start Packing moves the sample order to Packing in memory,
/// and packing photos (US-026) are kept in memory with the server's rules, without uploading.
class MockSellerOrderRepository implements SellerOrderRepository {
  static const PackingRules _rules = PackingRules();

  final DateTime Function() _now;
  late final List<IncomingOrder> _orders = _samples(_now());
  final Map<String, List<OrderProof>> _proofs = {};
  int _nextId = 0;

  MockSellerOrderRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  @override
  Future<PackingView> packing(String orderId) async => PackingView(
        order: _orders.firstWhere((o) => o.id == orderId),
        proofs: List.unmodifiable(_proofs[orderId] ?? const <OrderProof>[]),
        rules: _rules,
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
    if (width < _rules.minPixels || height < _rules.minPixels) {
      throw const ApiError(
          type: ApiErrorType.validation, message: 'Image quality low', code: _lowQuality);
    }
    return 'mock-media-${_nextId++}';
  }

  @override
  Future<OrderProof> attachProof(String orderId, String mediaId, ProofKind kind) async {
    final proofs = _proofs.putIfAbsent(orderId, () => []);
    if (proofs.where((p) => p.kind == kind).length >= _rules.max(kind)) {
      throw const ApiError(
          type: ApiErrorType.validation, message: 'Section full', code: 'ERROR_PROOF_LIMIT');
    }
    final proof = OrderProof(id: 'proof-$mediaId', kind: kind, uploadedAt: _now());
    proofs.add(proof);
    return proof;
  }

  @override
  Future<void> removeProof(String orderId, String proofId) async =>
      _proofs[orderId]?.removeWhere((p) => p.id == proofId);

  @override
  Future<IncomingOrder> completePacking(String orderId, PackageSize size) async {
    final proofs = _proofs[orderId] ?? const <OrderProof>[];
    for (final kind in ProofKind.values) {
      if (proofs.where((p) => p.kind == kind).length < _rules.min(kind)) {
        throw const ApiError(
            type: ApiErrorType.validation, message: 'Photos missing', code: 'ERROR_IMAGE_REQUIRED');
      }
    }
    final index = _orders.indexWhere((o) => o.id == orderId);
    final order = _orders[index];
    final ready = IncomingOrder(
      id: order.id,
      orderNumber: order.orderNumber,
      bucket: FulfilmentBucket.packing,
      orderState: 'SELLER_PROOF_UPLOADED',
      placedAt: order.placedAt,
      amount: order.amount,
      title: order.title,
      buyerName: order.buyerName,
      actions: const [SellerOrderAction.schedulePickup],
    );
    _orders[index] = ready;
    return ready;
  }

  static const String _lowQuality = 'WARNING_IMAGE_QUALITY_LOW';

  @override
  Future<IncomingOrdersPage> orders(
      {int page = 0, int size = SellerOrderRepository.pageSize}) async {
    final start = page * size;
    final items = _orders.skip(start).take(size).toList();
    return IncomingOrdersPage(items: items, page: page, hasMore: start + size < _orders.length);
  }

  @override
  Future<OrdersSummary> summary() async {
    int count(FulfilmentBucket bucket) => _orders.where((o) => o.bucket == bucket).length;
    return OrdersSummary(
      total: _orders.length,
      newOrders: count(FulfilmentBucket.newOrder),
      packing: count(FulfilmentBucket.packing),
      scheduled: count(FulfilmentBucket.scheduled),
      shipped: count(FulfilmentBucket.shipped),
    );
  }

  @override
  Future<IncomingOrder> startPacking(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    final order = _orders[index];
    if (order.bucket != FulfilmentBucket.newOrder) return order;
    final packing = IncomingOrder(
      id: order.id,
      orderNumber: order.orderNumber,
      bucket: FulfilmentBucket.packing,
      orderState: 'SELLER_PACKING_PENDING',
      placedAt: order.placedAt,
      amount: order.amount,
      title: order.title,
      buyerName: order.buyerName,
      actions: const [SellerOrderAction.continuePacking],
    );
    _orders
      ..removeAt(index)
      ..insert(index, packing)
      ..sort((a, b) => a.bucket.index.compareTo(b.bucket.index));
    return packing;
  }

  @override
  Future<IncomingOrder> markHandedOver(String orderId) async =>
      _orders.firstWhere((o) => o.id == orderId);

  static List<IncomingOrder> _samples(DateTime now) => [
        IncomingOrder(
          id: 'mock-1001',
          orderNumber: 'ORD-S-1001',
          bucket: FulfilmentBucket.newOrder,
          orderState: 'SHIPPING_MODE_SELECTED',
          tags: const [OrderTag.urgent],
          placedAt: now.subtract(const Duration(hours: 2)),
          amount: 42000,
          title: 'Vintage Leica M6 Film Camera',
          buyerName: 'Ananya Sharma',
          actions: const [SellerOrderAction.startPacking, SellerOrderAction.reject],
        ),
        IncomingOrder(
          id: 'mock-1000',
          orderNumber: 'ORD-S-1000',
          bucket: FulfilmentBucket.packing,
          orderState: 'SELLER_PACKING_PENDING',
          placedAt: now.subtract(const Duration(days: 1)),
          amount: 85000,
          title: 'Sony A7III Camera Body',
          buyerName: 'Rohan Mehta',
          actions: const [SellerOrderAction.continuePacking],
        ),
        IncomingOrder(
          id: 'mock-0999',
          orderNumber: 'ORD-S-0999',
          bucket: FulfilmentBucket.scheduled,
          orderState: 'PICKUP_SCHEDULED',
          placedAt: now.subtract(const Duration(days: 2)),
          amount: 18500,
          title: 'Mechanical Keyboard HHKB Pro 2',
          buyerName: 'Priya Iyer',
          actions: const [SellerOrderAction.viewSchedule, SellerOrderAction.reschedulePickup],
        ),
        IncomingOrder(
          id: 'mock-0998',
          orderNumber: 'ORD-S-0998',
          bucket: FulfilmentBucket.shipped,
          orderState: 'IN_TRANSIT',
          placedAt: now.subtract(const Duration(days: 3)),
          amount: 96000,
          title: 'iPad Pro 12.9" M2 (2024)',
          buyerName: 'Vikram Nair',
        ),
      ];
}
