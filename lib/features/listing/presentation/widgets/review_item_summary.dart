import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/plan_selection.dart';
import 'review_section_title.dart';

class ReviewItemSummary extends StatelessWidget {
  final ListingSummary summary;

  const ReviewItemSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final thumbnail = summary.thumbnailBytes;
    final metadata = [summary.categoryPath, summary.conditionLabel, summary.city]
        .where((value) => value.isNotEmpty)
        .join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.memory(
                  thumbnail,
                  width: 82,
                  height: 66,
                  fit: BoxFit.cover,
                  cacheWidth: 246,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 82,
                    height: 66,
                    child: ColoredBox(
                      color: AppColors.brandSurfaceTint,
                      child:
                          Icon(Icons.image_not_supported_outlined, color: AppColors.brandMutedText),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReviewSectionTitle(l10n.reviewItemSection),
                  const SizedBox(height: AppSpacing.xs),
                  Text(summary.title,
                      style: AppTextStyles.body.copyWith(
                        fontFamily: AppFonts.heading,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ],
        ),
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(metadata, style: AppTextStyles.bodySecondary),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(summary.description, style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(l10n.reviewListedPrice, style: AppTextStyles.bodySecondary)),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              fit: FlexFit.tight,
              child: Text(
                Formatters.money(double.tryParse(summary.price.replaceAll(',', '')) ?? 0),
                style: AppTextStyles.heading2.copyWith(fontSize: 22, height: 1.4),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
