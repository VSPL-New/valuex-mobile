import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/home_providers.dart';

/// Shown in place of the listings until Home knows where "near you" is.
class LocationPrompt extends StatelessWidget {
  final LocationNeed need;
  final VoidCallback onUseLocation;
  final VoidCallback onOpenSettings;
  final VoidCallback onUseSaved;

  const LocationPrompt({
    super.key,
    required this.need,
    required this.onUseLocation,
    required this.onOpenSettings,
    required this.onUseSaved,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (need) {
      LocationNeed.notAsked => null,
      LocationNeed.denied || LocationNeed.deniedForever => l10n.homeLocationDenied,
      LocationNeed.serviceOff => l10n.homeLocationServiceOff,
      LocationNeed.unavailable => l10n.homeLocationUnavailable,
    };
    final needsSettings = need == LocationNeed.deniedForever || need == LocationNeed.serviceOff;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.brandControlBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.homeLocationPromptTitle, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.homeLocationPromptBody, style: AppTextStyles.hint),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              FieldError(text: message),
            ],
            const SizedBox(height: AppSpacing.md),
            BrandGradientButton(
              label: needsSettings ? l10n.homeOpenSettings : l10n.homeUseMyLocation,
              onPressed: needsSettings ? onOpenSettings : onUseLocation,
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleToneButton(label: l10n.homeUseSavedLocation, onPressed: onUseSaved),
          ],
        ),
      ),
    );
  }
}
