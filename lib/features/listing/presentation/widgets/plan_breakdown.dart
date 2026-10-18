import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/seller_plan.dart';

/// What the seller pays for the selected plan, shown before they confirm: original price,
/// discount, GST and the total. A free plan shows "Free" and no payment wording.
class PlanBreakdown extends StatelessWidget {
  final SellerPlan plan;

  const PlanBreakdown({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.brandBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.planBreakdownTitle, style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (plan.isFree) ...[
              _Row(label: l10n.planBreakdownTotal, value: l10n.planFree, strong: true),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.planFreeNote,
                style: AppTextStyles.hint.copyWith(color: AppColors.brandForeground),
              ),
            ] else ...[
              if (plan.hasDiscount && plan.originalPrice != null)
                _Row(
                  label: l10n.planBreakdownOriginal,
                  value: Formatters.money(plan.originalPrice!),
                ),
              if (plan.hasDiscount)
                _Row(
                  label: l10n.planBreakdownDiscount(plan.discountPercent),
                  value: '−${Formatters.money(plan.discountAmount)}',
                  valueColor: AppColors.brandSuccessText,
                ),
              if (plan.gstAmount > 0)
                _Row(
                  label: plan.priceIncludesGst
                      ? l10n.planBreakdownGstIncluded
                      : l10n.planBreakdownGstAdded(_rate(plan.gstRatePercent)),
                  value: '${plan.priceIncludesGst ? '' : '+'}${Formatters.money(plan.gstAmount)}',
                ),
              const Divider(height: AppSpacing.lg, color: AppColors.brandDivider),
              _Row(
                label: l10n.planBreakdownTotal,
                value: Formatters.money(plan.totalAmount),
                strong: true,
              ),
              if (plan.priceIncludesGst && plan.gstAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    l10n.planInclusiveOfGst,
                    style: AppTextStyles.hint.copyWith(color: AppColors.brandForeground),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _rate(double rate) => rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 2);
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.strong = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final labelStyle = (strong ? AppTextStyles.cardTitle : AppTextStyles.bodySecondary)
        .copyWith(color: AppColors.brandForeground);
    final valueStyle = (strong ? AppTextStyles.cardPrice : AppTextStyles.body).copyWith(
      color: valueColor ?? AppColors.brandForeground,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
