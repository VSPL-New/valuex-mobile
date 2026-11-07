import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/locale_controller.dart';

/// "Save Language Preference": applies and stores the row chosen in [LanguageOptionList], then
/// calls [onSaved] so the screen goes back or the sheet closes.
class LanguageSaveBar extends ConsumerWidget {
  final VoidCallback onSaved;

  const LanguageSaveBar({super.key, required this.onSaved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BrandGradientButton(
      label: AppLocalizations.of(context).languageSave,
      onPressed: () async {
        final pending = ref.read(pendingLanguageProvider);
        await ref.read(localeControllerProvider.notifier).select(pending);
        if (context.mounted) onSaved();
      },
    );
  }
}
