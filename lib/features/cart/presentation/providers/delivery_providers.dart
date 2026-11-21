import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/cart_repository.dart';
import '../../domain/delivery.dart';

/// Which line, and which address the shipping is priced to ([addressId] null asks only what the line
/// allows).
class DeliveryQuery {
  final String itemId;
  final String? addressId;

  const DeliveryQuery(this.itemId, [this.addressId]);

  @override
  bool operator ==(Object other) =>
      other is DeliveryQuery && other.itemId == itemId && other.addressId == addressId;

  @override
  int get hashCode => Object.hash(itemId, addressId);
}

/// What a cart line allows for receiving the item (US-020). Auto-dispose, so it is read again on every
/// open and a failure shows Retry instead of retrying silently.
final deliveryOptionsProvider = FutureProvider.autoDispose.family<DeliveryOptions, DeliveryQuery>(
  (ref, query) =>
      ref.watch(cartRepositoryProvider).deliveryOptions(query.itemId, addressId: query.addressId),
  retry: noAutoRetry,
);
