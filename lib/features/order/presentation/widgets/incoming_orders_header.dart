import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/incoming_order.dart';
import 'order_count_tile.dart';

/// Back button, title, "{n} orders · {x} new" and the "{x} New" badge over a tint that fades into
/// the page background, as on Profile. The count line and badge wait for the counts.
class IncomingOrdersHeader extends StatelessWidget {
  final OrdersSummary? summary;
  final VoidCallback onBack;

  const IncomingOrdersHeader({super.key, required this.summary, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = summary;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brandSurfaceTint, AppColors.brandBackground],
        ),
        border: Border(bottom: BorderSide(color: AppColors.brandDivider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SquareBackButton(onPressed: onBack),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(l10n.sellerOrdersTitle, style: AppTextStyles.heading2),
                        ),
                        if (counts != null)
                          Text(
                            l10n.sellerOrdersSubtitle(counts.total, counts.newOrders),
                            style: AppTextStyles.hint,
                          ),
                      ],
                    ),
                  ),
                  if (counts != null && counts.newOrders > 0)
                    DecoratedBox(
                      decoration: const ShapeDecoration(
                        color: AppColors.brandMuted,
                        shape: StadiumBorder(),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        child: Text(
                          l10n.sellerOrdersNewBadge(cappedCount(counts.newOrders)),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.brandForeground,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
