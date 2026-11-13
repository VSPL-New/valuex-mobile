import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';

Future<bool> showVoiceNoticeSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const VoiceNoticeSheet(),
    ) ??
    false;

class VoiceNoticeSheet extends StatelessWidget {
  const VoiceNoticeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.voiceNoticeTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.voiceNoticeBody),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.voiceContinue,
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.voiceNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
