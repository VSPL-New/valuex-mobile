import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

/// The item and order reference at the top of Pack & Upload Proof (Make).
class PackingOrderCard extends StatelessWidget {
  final String title;
  final String orderNumber;

  const PackingOrderCard({super.key, required this.title, required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        border: Border.all(color: AppColors.brandBorder),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.brandPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(l10n.packingOrderRef(orderNumber), style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The four numbered packing steps on a blue tint (Make).
class PackingStepsCard extends StatelessWidget {
  const PackingStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [l10n.packingStep1, l10n.packingStep2, l10n.packingStep3, l10n.packingStep4];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.07),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.packingStepsTitle,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.brandInstruction,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final (index, step) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.brandPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandOnPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(step, style: AppTextStyles.bodySecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Payment of ₹… is held in escrow…" with the amount in bold green (Make, plan G12).
class EscrowNote extends StatelessWidget {
  final String amount;

  const EscrowNote({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context).packingEscrow(amount);
    final at = text.indexOf(amount);
    final strong = AppTextStyles.bodySecondary
        .copyWith(color: AppColors.brandSuccess, fontWeight: FontWeight.w700);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSuccessTint,
        border: Border.all(color: AppColors.brandSuccess.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: 18, color: AppColors.brandSuccess),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                at < 0
                    ? TextSpan(text: text)
                    : TextSpan(children: [
                        TextSpan(text: text.substring(0, at)),
                        TextSpan(text: amount, style: strong),
                        TextSpan(text: text.substring(at + amount.length)),
                      ]),
                style: AppTextStyles.bodySecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
