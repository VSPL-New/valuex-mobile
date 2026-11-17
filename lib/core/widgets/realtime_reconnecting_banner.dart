import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../realtime/realtime_event.dart';
import '../realtime/realtime_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../../l10n/app_localizations.dart';

/// A thin strip telling the user the live connection is down and being restored (US-130). Place it
/// where fresh data matters, such as an open conversation; it is announced to screen readers when it
/// appears and takes no room while the connection is fine.
class RealtimeReconnectingBanner extends ConsumerWidget {
  const RealtimeReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeStatusProvider);
    if (status != RealtimeStatus.reconnecting && status != RealtimeStatus.degraded) {
      return const SizedBox.shrink();
    }
    final label = AppLocalizations.of(context).realtimeReconnecting;
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: ColoredBox(
        color: AppColors.brandMuted,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.sync_rounded, size: 14, color: AppColors.brandForeground),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
