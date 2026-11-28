import 'dart:typed_data';

import '../entities/incoming_order.dart';
import '../entities/packing.dart';

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

  /// Pack & Upload Proof (US-026): the order, the photos so far, the packed size and the rules.
  Future<PackingView> packing(String orderId);

  /// Uploads a packing photo straight to storage and returns its media id for [attachProof].
  Future<String> uploadProofPhoto({
    required String ownerId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
    required int width,
    required int height,
  });

  /// Attaches an uploaded photo to the packing as a draft; the same photo again returns the same.
  Future<OrderProof> attachProof(String orderId, String mediaId, ProofKind kind);

  /// Removes a draft photo; one already gone succeeds.
  Future<void> removeProof(String orderId, String proofId);

  /// Submits the photos and the packed size; the order then waits for pickup scheduling.
  Future<IncomingOrder> completePacking(String orderId, PackageSize size);
}
