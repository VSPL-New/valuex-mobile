import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// A pill at the top of a conversation reminding people to keep chats and payments on JustQlic and
/// never share OTPs or bank details. It can be dismissed, and then stays away on this install.
class SafetyBanner extends ConsumerStatefulWidget {
  const SafetyBanner({super.key});

  @override
  ConsumerState<SafetyBanner> createState() => _SafetyBannerState();
}

class _SafetyBannerState extends ConsumerState<SafetyBanner> {
  bool _dismissed = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dismissed =
        await ref.read(preferencesServiceProvider).getBool(StorageKeys.chatSafetyBannerDismissed);
    if (mounted) setState(() => _dismissed = dismissed ?? false);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    await ref.read(preferencesServiceProvider).setBool(StorageKeys.chatSafetyBannerDismissed, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandMuted,
          borderRadius: BorderRadius.circular(AppRadius.xl + 8),
          border: Border.all(color: AppColors.brandBorder),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
          child: Row(
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.shield_outlined, size: 18, color: AppColors.brandLink),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    l10n.chatSafetyBanner,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.chatSafetyBannerDismiss,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.brandMutedText),
                onPressed: _dismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
