import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/saved_hearts_controller.dart';

/// The heart that saves or removes a listing (US-073). It starts from the server's [saved] flag, shows a
/// tap at once and puts it back with a message when the server refuses. Every heart of the same
/// listing shows the same state.
class SaveHeart extends ConsumerWidget {
  /// Size of the circle behind the icon; the tap area is always at least 48 dp.
  static const double _circle = 34;

  final String listingId;

  /// What the server said when the card or page was loaded.
  final bool saved;

  /// The circle makes the heart readable over a photo; off for a plain background.
  final bool overPhoto;

  const SaveHeart({super.key, required this.listingId, required this.saved, this.overPhoto = true});

  Future<void> _tap(BuildContext context, WidgetRef ref, bool current) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref.read(savedHeartsProvider.notifier).toggle(
          listingId,
          currentlySaved: current,
        );
    if (outcome == null || !outcome.failed) return;
    final text = switch (outcome.status) {
      SaveHeartStatus.limitReached =>
        outcome.max == null ? l10n.savedItemLimitUnknown : l10n.savedItemLimit(outcome.max!),
      SaveHeartStatus.unavailable => l10n.savedItemUnavailableNow,
      _ => l10n.savedItemSaveFailed,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(savedHeartsProvider.select((hearts) => hearts[listingId])) ?? saved;
    return Semantics(
      button: true,
      toggled: current,
      label: current ? l10n.savedItemRemove : l10n.savedItemSave,
      excludeSemantics: true,
      onTap: () => _tap(context, ref, current),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(context, ref, current),
        child: SizedBox(
          width: AppSpacing.xl + AppSpacing.md,
          height: AppSpacing.xl + AppSpacing.md,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: overPhoto ? AppColors.brandSurface : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: _circle,
                height: _circle,
                child: Icon(
                  current ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color: current ? AppColors.brandError : AppColors.brandForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
