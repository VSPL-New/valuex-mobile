import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/incoming_order.dart';

/// The icon of each group, shared by the chips and the count tiles (LLD A.8.3: a status is told by
/// its icon and text, never by colour alone).
IconData bucketIcon(FulfilmentBucket bucket) => switch (bucket) {
      FulfilmentBucket.newOrder => Icons.error_outline,
      FulfilmentBucket.packing => Icons.inventory_2_outlined,
      FulfilmentBucket.scheduled => Icons.schedule,
      FulfilmentBucket.shipped => Icons.local_shipping_outlined,
    };

/// The status of a card: the group's chip, or the more precise one a tag gives.
class OrderStatusChip extends StatelessWidget {
  final IncomingOrder order;

  const OrderStatusChip({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _status(AppLocalizations.of(context));
    return DecoratedBox(
      decoration: const ShapeDecoration(color: AppColors.brandSurfaceTint, shape: StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.brandForeground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.brandForeground,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String) _status(AppLocalizations l10n) {
    if (order.has(OrderTag.handedOver)) {
      return (Icons.check_circle_outline, l10n.sellerOrdersChipHandedOver);
    }
    if (order.has(OrderTag.returning)) return (Icons.undo, l10n.sellerOrdersChipReturning);
    if (order.has(OrderTag.arrangingPickup)) {
      return (Icons.event_outlined, l10n.sellerOrdersChipArranging);
    }
    final label = switch (order.bucket) {
      FulfilmentBucket.newOrder => l10n.sellerOrdersChipNew,
      FulfilmentBucket.packing => l10n.sellerOrdersChipPacking,
      FulfilmentBucket.scheduled => l10n.sellerOrdersChipScheduled,
      FulfilmentBucket.shipped => l10n.sellerOrdersChipShipped,
    };
    return (bucketIcon(order.bucket), label);
  }
}
