import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/notification_presentation.dart';
import '../../domain/entities/incoming_order.dart';
import 'buyer_initials_avatar.dart';
import 'order_status_chip.dart';

/// One order on the seller's Incoming Orders (US-112): reference, tags and status, the item, the
/// buyer and the time, then the buttons the server offers and the order details button.
class IncomingOrderCard extends StatelessWidget {
  final IncomingOrder order;

  /// An action of this card is running: its buttons are disabled.
  final bool busy;
  final ValueChanged<SellerOrderAction> onAction;
  final VoidCallback onDetails;

  const IncomingOrderCard({
    super.key,
    required this.order,
    this.busy = false,
    required this.onAction,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        border: Border.all(color: AppColors.brandBorder),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(order: order),
          if (_extraTags.isNotEmpty) _Tags(order: order, tags: _extraTags),
          _ItemRow(order: order),
          if (order.bookingError != null)
            _BookingError(message: _bookingErrorText(l10n, order.bookingError!)),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: _Actions(order: order, busy: busy, onAction: onAction, onDetails: onDetails),
          ),
        ],
      ),
    );
  }

  /// Tags shown as pills below the header; URGENT sits in the header, and the status tags
  /// (arranging, returning, handed over) are shown by the chip.
  List<OrderTag> get _extraTags => [
        for (final tag in order.tags)
          if (tag == OrderTag.selfPickup || tag == OrderTag.pickupFailed) tag,
      ];

  static String _bookingErrorText(AppLocalizations l10n, String code) =>
      code == 'ERROR_NO_LOGISTICS_AVAILABLE'
          ? l10n.sellerOrdersNoLogistics
          : l10n.sellerOrdersBookingFailed;
}

class _HeaderRow extends StatelessWidget {
  final IncomingOrder order;

  const _HeaderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brandDivider)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('#${order.orderNumber}', style: AppTextStyles.label.copyWith(letterSpacing: 0)),
              if (order.has(OrderTag.urgent))
                DecoratedBox(
                  decoration: const ShapeDecoration(
                    shape: StadiumBorder(side: BorderSide(color: AppColors.brandAccent)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    child: Text(
                      l10n.sellerOrdersTagUrgent,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          OrderStatusChip(order: order),
        ],
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  final IncomingOrder order;
  final List<OrderTag> tags;

  const _Tags({required this.order, required this.tags});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 0),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final tag in tags)
            DecoratedBox(
              decoration: const ShapeDecoration(
                color: AppColors.brandSurface,
                shape: StadiumBorder(side: BorderSide(color: AppColors.brandControlBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tag == OrderTag.selfPickup ? Icons.place_outlined : Icons.error_outline,
                      size: 16,
                      color: AppColors.brandForeground,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tag == OrderTag.selfPickup
                            ? l10n.sellerOrdersTagSelfPickup
                            : l10n.sellerOrdersTagPickupFailed,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.brandForeground,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final IncomingOrder order;

  const _ItemRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final image = order.imageUrl;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            image: true,
            label: l10n.sellerOrdersItemPhoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 64,
                height: 64,
                child: image == null || image.isEmpty
                    ? const ColoredBox(
                        color: AppColors.brandSurfaceTint,
                        child: Icon(Icons.image_outlined, color: AppColors.brandMutedText),
                      )
                    : AppImage(source: image, cacheWidth: 192),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                Text(Formatters.currency(order.amount), style: AppTextStyles.cardPrice),
                const SizedBox(height: 2),
                Row(
                  children: [
                    BuyerInitialsAvatar(name: order.buyerName),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        order.buyerName == null || order.buyerName!.trim().isEmpty
                            ? l10n.sellerOrdersBuyerUnnamed
                            : l10n.sellerOrdersBuyer(order.buyerName!),
                        style: AppTextStyles.hint,
                      ),
                    ),
                  ],
                ),
                Text(notificationTimeLabel(context, order.placedAt), style: AppTextStyles.hint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingError extends StatelessWidget {
  final String message;

  const _BookingError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
              child: Icon(Icons.error_outline, size: 18, color: AppColors.brandError)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.error)),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final IncomingOrder order;
  final bool busy;
  final ValueChanged<SellerOrderAction> onAction;
  final VoidCallback onDetails;

  const _Actions({
    required this.order,
    required this.busy,
    required this.onAction,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = _DetailsButton(onPressed: onDetails);
    final actions = order.actions;
    if (actions.isEmpty) {
      final shipped = order.bucket == FulfilmentBucket.shipped && order.tags.isEmpty;
      return Row(
        children: [
          Expanded(
            child: shipped
                ? Row(
                    children: [
                      const ExcludeSemantics(
                        child: Icon(Icons.check_circle_outline, color: AppColors.brandForeground),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                          child: Text(l10n.sellerOrdersShippedStatus, style: AppTextStyles.body)),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          details,
        ],
      );
    }
    final primary =
        actions.firstWhere((a) => a != SellerOrderAction.reject, orElse: () => actions.first);
    final rest = [
      for (final action in actions)
        if (action != primary) action,
    ];
    final rejectBeside = rest.length == 1 && rest.single == SellerOrderAction.reject;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _button(l10n, primary)),
            if (rejectBeside) ...[
              const SizedBox(width: AppSpacing.sm),
              _button(l10n, SellerOrderAction.reject),
            ],
            const SizedBox(width: AppSpacing.sm),
            details,
          ],
        ),
        if (!rejectBeside)
          for (final action in rest) ...[
            const SizedBox(height: AppSpacing.sm),
            _button(l10n, action),
          ],
      ],
    );
  }

  Widget _button(AppLocalizations l10n, SellerOrderAction action) {
    final onPressed = busy ? null : () => onAction(action);
    return switch (action) {
      SellerOrderAction.startPacking => BrandGradientButton(
          label: l10n.sellerOrdersStartPacking,
          onPressed: onPressed,
          isLoading: busy,
        ),
      SellerOrderAction.reject =>
        _RejectButton(label: l10n.sellerOrdersReject, onPressed: onPressed),
      SellerOrderAction.continuePacking => SingleToneButton(
          label: l10n.sellerOrdersContinuePacking,
          leadingIcon: Icons.inventory_2_outlined,
          onPressed: onPressed,
        ),
      SellerOrderAction.schedulePickup => SingleToneButton(
          label: l10n.sellerOrdersSchedulePickup,
          leadingIcon: Icons.inventory_2_outlined,
          onPressed: onPressed,
        ),
      SellerOrderAction.viewSchedule => SingleToneButton(
          label: l10n.sellerOrdersViewSchedule,
          leadingIcon: Icons.schedule,
          onPressed: onPressed,
        ),
      SellerOrderAction.reschedulePickup => SingleToneButton(
          label: l10n.sellerOrdersReschedulePickup,
          leadingIcon: Icons.schedule,
          onPressed: onPressed,
        ),
      SellerOrderAction.viewPickupDetails => SingleToneButton(
          label: l10n.sellerOrdersViewPickupDetails,
          leadingIcon: Icons.place_outlined,
          onPressed: onPressed,
        ),
      SellerOrderAction.markHandedOver => SingleToneButton(
          label: l10n.sellerOrdersMarkHandedOver,
          leadingIcon: Icons.check_circle_outline,
          onPressed: onPressed,
        ),
    };
  }
}

/// Destructive secondary: brand error text and border, 56 high like the buttons beside it.
class _RejectButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RejectButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.buttonMedium),
        foregroundColor: AppColors.brandError,
        side: const BorderSide(color: AppColors.brandError, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        textStyle: AppTextStyles.button,
      ),
      child: Text(label),
    );
  }
}

/// The 48 dp order details button (US-023); labelled for screen readers.
class _DetailsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DetailsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).sellerOrdersDetails;
    return SizedBox(
      width: AppSizes.buttonMedium,
      height: AppSizes.buttonMedium,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.brandForeground,
          side: const BorderSide(color: AppColors.brandControlBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        ),
        child: Tooltip(message: label, child: Icon(Icons.chevron_right, semanticLabel: label)),
      ),
    );
  }
}
