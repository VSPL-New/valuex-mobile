import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'confirmation_sheet.dart';

/// The reason codes the server gives for a major edit (US-010), in the order they are shown.
const List<String> remoderationReasonCodes = [
  'PRICE_CHANGE_TOO_HIGH',
  'CONTENT_NEEDS_REVIEW',
  'PHOTOS_ADDED',
];

/// The reasons out of the 409's `reasons` detail, a comma separated list.
List<String> parseRemoderationReasons(String? reasons) {
  final sent = (reasons ?? '').split(',').map((reason) => reason.trim()).toSet();
  return [
    for (final code in remoderationReasonCodes)
      if (sent.contains(code)) code,
  ];
}

String remoderationReasonText(AppLocalizations l10n, String code) => switch (code) {
      'PRICE_CHANGE_TOO_HIGH' => l10n.remoderationReasonPrice,
      'CONTENT_NEEDS_REVIEW' => l10n.remoderationReasonContent,
      _ => l10n.remoderationReasonPhotos,
    };

/// Tells the seller a change sends the listing back to review, and why. True when they confirm;
/// nothing has been saved before that.
Future<bool> showRemoderationSheet(BuildContext context, List<String> reasons) {
  final l10n = AppLocalizations.of(context);
  return showConfirmationSheet(
    context,
    title: l10n.remoderationTitle,
    body: [
      Text(l10n.remoderationBody, style: AppTextStyles.body),
      const SizedBox(height: AppSpacing.sm),
      for (final reason in reasons)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.info_outline_rounded, size: 20, color: AppColors.brandForeground),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text(remoderationReasonText(l10n, reason),
                      style: AppTextStyles.bodySecondary)),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.xs),
      Text(l10n.remoderationPlanRuns, style: AppTextStyles.bodySecondary),
    ],
    confirmLabel: l10n.remoderationConfirm,
    cancelLabel: l10n.remoderationCancel,
  );
}
