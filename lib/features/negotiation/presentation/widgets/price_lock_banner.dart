import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../negotiation_format.dart';
import 'countdown_text.dart';

/// The accepted price and, for goods, how long it stays locked (US-017). A property has no lock:
/// the price is agreed and the owner closes the deal.
class PriceLockBanner extends StatelessWidget {
  final num agreedPrice;
  final DateTime? lockEndsAt;
  final DateTime serverTime;

  const PriceLockBanner({
    super.key,
    required this.agreedPrice,
    required this.lockEndsAt,
    required this.serverTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = Formatters.money(agreedPrice);
    final ends = lockEndsAt;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSuccessTint,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, size: 20, color: AppColors.brandSuccessText),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ends == null
                  ? _text(l10n.negotiationPropertyAgreed(amount))
                  : CountdownText(
                      target: ends,
                      serverTime: serverTime,
                      builder: (context, remaining) => _text(
                        l10n.negotiationLockBanner(amount, durationLabel(l10n, remaining)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _text(String text) => Semantics(
        container: true,
        liveRegion: true,
        label: text,
        excludeSemantics: true,
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(color: AppColors.brandSuccessText),
        ),
      );
}
