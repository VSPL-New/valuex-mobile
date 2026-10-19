import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../l10n/app_localizations.dart';

/// "Let AI do the work for you" banner at the top of the photo step.
class AiIntroCard extends StatelessWidget {
  const AiIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sellAiCardStart, AppColors.sellAiCardEnd],
        ),
        boxShadow: SoftCard.decoration().boxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Stack(
              clipBehavior: Clip.none,
              children: [
                IconTile(
                  icon: Icons.photo_camera_outlined,
                  size: 48,
                  gradient: AppGradients.brand,
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: ExcludeSemantics(
                    child: Icon(Icons.auto_awesome, size: 20, color: AppColors.sellSparkle),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.sellAiTitle, style: AppTextStyles.cardTitle),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.sellAiBody,
                    style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandForeground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
