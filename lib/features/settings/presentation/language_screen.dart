import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/language_option_list.dart';
import 'widgets/language_save_bar.dart';

/// Profile > Language: choose English or Hindi, then save.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SquareBackButton(onPressed: () => _back(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(
                    child: Icon(Icons.language, size: 28, color: AppColors.brandPrimary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(l10n.languageTitle, style: AppTextStyles.heading2),
                        ),
                        Text(l10n.languageSubtitle, style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.brandBorder),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LanguageOptionList(),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.brandSurface,
                border: Border(top: BorderSide(color: AppColors.brandBorder)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: LanguageSaveBar(onSaved: () => _back(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
