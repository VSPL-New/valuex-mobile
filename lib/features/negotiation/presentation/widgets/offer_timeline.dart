import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/negotiation.dart';

/// Every price put forward, oldest first: who, which round and how much. The latest one is
/// emphasised (US-017).
class OfferTimeline extends StatelessWidget {
  final List<NegotiationOffer> offers;
  final NegotiationRole viewer;

  const OfferTimeline({super.key, required this.offers, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < offers.length; i++)
          _OfferRow(offer: offers[i], viewer: viewer, latest: i == offers.length - 1, l10n: l10n),
      ],
    );
  }
}

class _OfferRow extends StatelessWidget {
  final NegotiationOffer offer;
  final NegotiationRole viewer;
  final bool latest;
  final AppLocalizations l10n;

  const _OfferRow({
    required this.offer,
    required this.viewer,
    required this.latest,
    required this.l10n,
  });

  String get _party => offer.party == viewer
      ? l10n.negotiationPartyYou
      : offer.party == NegotiationRole.buyer
          ? l10n.negotiationPartyBuyer
          : l10n.negotiationPartySeller;

  @override
  Widget build(BuildContext context) {
    final amount = Formatters.money(offer.amount);
    final label = l10n.negotiationOfferBy(_party, offer.round);
    return Semantics(
      container: true,
      label: '$label, $amount',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: latest ? AppColors.brandSurfaceTint : AppColors.brandSurface,
            border: Border.all(color: latest ? AppColors.brandPrimary : AppColors.brandBorder),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                  ),
                ),
                Text(
                  amount,
                  style: latest
                      ? AppTextStyles.cardPrice
                      : AppTextStyles.body.copyWith(color: AppColors.brandForeground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
