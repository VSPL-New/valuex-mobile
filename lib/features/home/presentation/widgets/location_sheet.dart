import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/home_providers.dart';
import 'saved_location_dialog.dart';

/// Lets the user measure "near you" from the device location or from one of their saved
/// addresses. There is no way to type an address here.
Future<void> showLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => _LocationSheet(hostContext: context),
  );
}

class _LocationSheet extends ConsumerWidget {
  /// The screen that opened the sheet; the sheet itself is gone by the time the dialog opens.
  final BuildContext hostContext;

  const _LocationSheet({required this.hostContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(homeLocationControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.homeLocationSheetTitle, style: AppTextStyles.heading2),
          ),
          const SizedBox(height: AppSpacing.md),
          BrandGradientButton(
            label: l10n.homeUseMyLocation,
            onPressed: () {
              Navigator.of(context).pop();
              controller.useDeviceLocation();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleToneButton(
            label: l10n.homeUseSavedLocation,
            onPressed: () {
              Navigator.of(context).pop();
              showSavedLocationDialog(hostContext);
            },
          ),
        ],
      ),
    );
  }
}
