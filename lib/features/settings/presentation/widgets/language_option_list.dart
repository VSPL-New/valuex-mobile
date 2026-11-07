import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/supported_languages.dart';
import '../providers/locale_controller.dart';

/// The language's name in the language the app is showing now ("Hindi", "हिन्दी").
String languageName(AppLocalizations l10n, SupportedLanguage language) {
  return switch (language.code) {
    'hi' => l10n.languageNameHindi,
    _ => l10n.languageNameEnglish,
  };
}

/// One card with a row per supported language. A tap only marks the row; the language changes
/// when the user saves (see [LanguageSaveBar]).
class LanguageOptionList extends ConsumerWidget {
  const LanguageOptionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingLanguageProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.brandBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(
          children: [
            for (var i = 0; i < supportedLanguages.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.brandBorder),
              _LanguageRow(
                language: supportedLanguages[i],
                selected: supportedLanguages[i].code == pending.languageCode,
                onTap: () =>
                    ref.read(pendingLanguageProvider.notifier).choose(supportedLanguages[i].locale),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final SupportedLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({required this.language, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = languageName(l10n, language);

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: selected ? l10n.languageSelected(name) : name,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? AppColors.brandSurfaceTint : AppColors.brandSurface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.cardTitle),
                        Text(
                          language.nativeName,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.brandMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 28,
                        child: Icon(Icons.check, size: 18, color: AppColors.brandOnPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
