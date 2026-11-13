import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';

class VoiceSearchButton extends StatelessWidget {
  const VoiceSearchButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).voiceButtonLabel;
    return IconButton(
      tooltip: label,
      constraints: const BoxConstraints(
        minWidth: AppSizes.minTouchTarget,
        minHeight: AppSizes.minTouchTarget,
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.mic_none_rounded),
    );
  }
}
