import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Template Terms and Conditions page; the legal text is added later.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      l10n.termsSection1,
      l10n.termsSection2,
      l10n.termsSection3,
      l10n.termsSection4,
      l10n.termsSection5,
      l10n.termsSection6,
      l10n.termsSection7,
      l10n.termsSection8,
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.termsTitle, style: AppTextStyles.heading2)),
                  IconButton(
                    tooltip: l10n.commonClose,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.brandForeground),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Text(l10n.termsLastUpdated, style: AppTextStyles.hint),
                  for (final title in sections) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.termsPlaceholder, style: AppTextStyles.bodySecondary),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
