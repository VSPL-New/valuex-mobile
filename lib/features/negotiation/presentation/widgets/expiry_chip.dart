import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../negotiation_format.dart';
import 'countdown_text.dart';

/// "Expires in 4h 20m" while an answer is awaited, counted from the server's clock.
class ExpiryChip extends StatelessWidget {
  final DateTime expiresAt;
  final DateTime serverTime;

  const ExpiryChip({super.key, required this.expiresAt, required this.serverTime});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CountdownText(
      target: expiresAt,
      serverTime: serverTime,
      builder: (context, remaining) {
        final text = remaining == Duration.zero
            ? l10n.negotiationExpiredChip
            : l10n.negotiationExpiresIn(durationLabel(l10n, remaining));
        return Semantics(
          container: true,
          label: text,
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandSurfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.brandMutedText),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      text,
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
