import '../entities/incoming_order.dart';

/// The seller's Incoming Orders (US-112, Sprint 6 LLD A.4). The real implementation calls the
/// backend; the mock one serves the Figma Make sample orders.
abstract class SellerOrderRepository {
  static const int pageSize = 20;

  /// One page, New first, then Packing, Scheduled and Shipped, newest first in each.
  Future<IncomingOrdersPage> orders({int page = 0, int size = pageSize});

  Future<OrdersSummary> summary();

  /// Moves a New delivery order to Packing; a repeat returns the same order.
  Future<IncomingOrder> startPacking(String orderId);

  /// Records that the buyer collected a self-pickup item; a repeat returns the same order.
  Future<IncomingOrder> markHandedOver(String orderId);
}
