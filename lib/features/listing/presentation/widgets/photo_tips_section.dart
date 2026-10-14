import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// "Photo tips for best results": four example tiles, each marked as a good practice.
class PhotoTipsSection extends StatelessWidget {
  const PhotoTipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tips = [
      (Icons.wb_sunny_outlined, l10n.sellTipLighting),
      (Icons.threesixty, l10n.sellTipAngles),
      (Icons.zoom_in, l10n.sellTipDetails),
      (Icons.headphones_outlined, l10n.sellTipAccessories),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.sellTipsTitle, style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < tips.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _TipTile(icon: tips[i].$1, label: tips[i].$2)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  static const double _badge = 20;

  final IconData icon;
  final String label;

  const _TipTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.brandSurface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(icon, size: 32, color: AppColors.brandPrimary),
                  ),
                ),
                const Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: CircleAvatar(
                    radius: _badge / 2,
                    backgroundColor: AppColors.brandSuccess,
                    child: Icon(Icons.check, size: 14, color: AppColors.brandOnPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.tipCaption),
        ],
      ),
    );
  }
}
