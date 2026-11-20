import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../negotiation/presentation/negotiation_format.dart';
import '../../../negotiation/presentation/widgets/countdown_text.dart';
import '../../domain/cart.dart';
import '../cart_error_messages.dart';

/// One item of the cart (US-019): photo, title, the agreed price, where the line stands, how long the
/// price and the line last (counted from the server's clock), what is left to choose and a Remove
/// button. The card is spoken as one sentence; Remove stays a separate control of at least 48 dp.
class CartLineCard extends StatelessWidget {
  final CartLine line;
  final String sellerName;
  final DateTime serverTime;
  final VoidCallback onRemove;

  const CartLineCard({
    super.key,
    required this.line,
    required this.sellerName,
    required this.serverTime,
    required this.onRemove,
  });

  static String statusLabel(AppLocalizations l10n, CartLineStatus status) => switch (status) {
        CartLineStatus.accepted => l10n.cartStatusAccepted,
        CartLineStatus.pending => l10n.cartStatusPending,
        CartLineStatus.expired => l10n.cartStatusExpired,
        CartLineStatus.unavailable => l10n.cartStatusUnavailable,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = line.title ?? l10n.cartProblemUnavailable;
    final price = Formatters.money(line.agreedPrice);
    final status = statusLabel(l10n, line.status);
    final problem = cartProblemText(l10n, line.problem);
    final priceChanged = line.problem == 'ERROR_PRICE_CHANGED' && line.currentPrice != null;
    final details = Semantics(
      container: true,
      label: [
        l10n.cartLineLabel(title, price, status, sellerName),
        if (problem != null) problem,
      ].join('. '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Photo(url: line.imageUrl, dimmed: !line.status.payable),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(color: AppColors.brandForeground),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.cartAgreedPrice(price),
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.brandForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (priceChanged)
                  Text(
                    l10n.cartNowAsking(Formatters.money(line.currentPrice!)),
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusBadge(status: line.status, label: status),
                    if (line.status.payable && line.agreementValidUntil != null)
                      _TimeText(
                        target: line.agreementValidUntil!,
                        serverTime: serverTime,
                        text: l10n.cartPriceValidFor,
                        icon: Icons.lock_clock_outlined,
                      ),
                  ],
                ),
                if (problem != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    problem,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandError),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.cartDeliveryChoose,
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                ),
                if (line.problem != 'ERROR_CART_EXPIRED')
                  _TimeText(
                    target: line.expiresAt,
                    serverTime: serverTime,
                    text: l10n.cartRemovesIn,
                    icon: Icons.schedule,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandBorder),
      ),
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            details,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                  foregroundColor: AppColors.brandLink,
                  textStyle: AppTextStyles.linkSmall,
                ),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.cartRemove),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String? url;
  final bool dimmed;

  const _Photo({required this.url, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.brandSurfaceTint,
      child: const Icon(Icons.image_outlined, color: AppColors.brandMutedText),
    );
    return ExcludeSemantics(
      child: Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: url == null
              ? placeholder
              : Image.network(
                  url!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => placeholder,
                ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CartLineStatus status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      CartLineStatus.accepted => (AppColors.brandSuccessTint, AppColors.brandSuccessText),
      CartLineStatus.pending => (AppColors.brandSurfaceTint, AppColors.brandMutedText),
      CartLineStatus.expired || CartLineStatus.unavailable => (
          AppColors.brandErrorTint,
          AppColors.brandError,
        ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(color: foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// "Price held for 14m": the time left to [target], counted from the server's clock.
class _TimeText extends StatelessWidget {
  final DateTime target;
  final DateTime serverTime;
  final String Function(String duration) text;
  final IconData icon;

  const _TimeText({
    required this.target,
    required this.serverTime,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CountdownText(
      target: target,
      serverTime: serverTime,
      builder: (context, remaining) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandMutedText),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text(durationLabel(l10n, remaining)),
              style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
            ),
          ),
        ],
      ),
    );
  }
}
