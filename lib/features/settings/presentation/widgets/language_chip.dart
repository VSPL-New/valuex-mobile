import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/supported_languages.dart';
import '../providers/locale_controller.dart';
import 'language_option_list.dart';
import 'language_save_bar.dart';

/// Opens the language choice as a bottom sheet, for screens shown before sign-in where the
/// Profile route is not available.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.languageSheetTitle, style: AppTextStyles.heading2),
          ),
          const SizedBox(height: AppSpacing.md),
          const LanguageOptionList(),
          const SizedBox(height: AppSpacing.lg),
          LanguageSaveBar(onSaved: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

/// Small globe-and-name control that opens the language sheet.
class LanguageChip extends ConsumerWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = languageFor(ref.watch(localeControllerProvider));
    final name = languageName(l10n, current);

    return Semantics(
      button: true,
      label: l10n.languageChipLabel(name),
      excludeSemantics: true,
      onTap: () => showLanguageSheet(context),
      child: Material(
        color: AppColors.brandSurface,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.brandControlBorder)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showLanguageSheet(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 18, color: AppColors.brandLink),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    current.nativeName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
