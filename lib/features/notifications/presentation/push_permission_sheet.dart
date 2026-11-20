import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/storage/preferences_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/single_tone_button.dart';
import '../../../l10n/app_localizations.dart';

/// Asks for the notification permission the first time the person is in a conversation (US-131),
/// after a short explanation, never at launch. Any answer is remembered, so the sheet is shown
/// once; a person who said no finds the shortcut to the system settings on the Notifications page.
/// Does nothing where push is not available, or when notifications are already allowed.
Future<void> maybeAskForPushPermission(BuildContext context, WidgetRef ref) async {
  final service = ref.read(pushServiceProvider);
  if (!service.isAvailable) return;
  final preferences = ref.read(preferencesServiceProvider);
  if (await preferences.getBool(StorageKeys.pushPermissionAsked) ?? false) return;
  if (await service.permissionGranted()) return;
  if (!context.mounted) return;

  final accepted = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.brandSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => const PushPermissionSheet(),
  );
  await preferences.setBool(StorageKeys.pushPermissionAsked, true);
  if (accepted == true) await service.requestPermission();
  // Tells the server the answer, so a refusal is never pushed to.
  await ref.read(pushRegistrationProvider).sync();
}

/// The explanation shown before the system prompt. Both actions are at least 48 dp tall and work
/// at large text.
class PushPermissionSheet extends StatelessWidget {
  const PushPermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExcludeSemantics(
            child:
                Icon(Icons.notifications_active_outlined, size: 40, color: AppColors.brandPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(l10n.pushPromptTitle, style: AppTextStyles.heading2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.pushPromptBody, style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.lg),
          BrandGradientButton(
            label: l10n.pushPromptAllow,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleToneButton(
            label: l10n.pushPromptLater,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

/// A strip on the Notifications page for a phone where notifications are off: one tap opens the
/// system settings. It shows nothing where push is not available or notifications are on, and
/// checks again when the person comes back from the settings.
class PushOffBanner extends ConsumerStatefulWidget {
  const PushOffBanner({super.key});

  @override
  ConsumerState<PushOffBanner> createState() => _PushOffBannerState();
}

class _PushOffBannerState extends ConsumerState<PushOffBanner> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(pushPermissionGrantedProvider);
    // The person may have changed the permission in the settings: tell the server.
    unawaited(ref.read(pushRegistrationProvider).sync());
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(pushServiceProvider).isAvailable) return const SizedBox.shrink();
    final granted = ref.watch(pushPermissionGrantedProvider).value;
    if (granted != false) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Semantics(
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandSurfaceTint,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.brandBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.notifications_off_outlined, color: AppColors.brandMutedText),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pushOffTitle, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.pushOffBody, style: AppTextStyles.hint),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize:
                                const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.brandLink,
                            textStyle: AppTextStyles.linkSmall,
                          ),
                          onPressed: () => unawaited(ref.read(appSettingsOpenerProvider)()),
                          child: Text(l10n.pushOffAction),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
