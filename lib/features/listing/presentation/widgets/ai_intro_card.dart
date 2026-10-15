import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// "Let AI do the work for you" banner at the top of the photo step.
class AiIntroCard extends StatelessWidget {
  static const double _iconBox = 72;

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
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: _iconBox,
                height: _iconBox,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: const Icon(Icons.photo_camera_outlined,
                            size: 36, color: AppColors.brandOnPrimary),
                      ),
                    ),
                    const Positioned(
                      right: -6,
                      bottom: -6,
                      child: Icon(Icons.auto_awesome, size: 22, color: AppColors.sellSparkle),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.sellAiTitle, style: AppTextStyles.sectionTitle),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.sellAiBody, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
