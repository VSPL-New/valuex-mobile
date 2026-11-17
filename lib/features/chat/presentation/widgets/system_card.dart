import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat.dart';

/// A card the system writes into the conversation. The listing card shows what the chat is about
/// at the moment it started; an offer card (US-017) says what happened in the negotiation and opens
/// it; call cards (later) show a neutral line until they have their own look.
class SystemCard extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onOpenListing;

  /// Whether the person looking is the buyer, so an offer card can say "You" for their own steps.
  final bool viewerIsBuyer;

  /// Opens the negotiation of an offer card.
  final ValueChanged<String>? onOpenNegotiation;

  const SystemCard({
    super.key,
    required this.message,
    this.onOpenListing,
    this.viewerIsBuyer = true,
    this.onOpenNegotiation,
  });

  /// The line of an offer card, or null for a kind this version does not know.
  String? _offerText(AppLocalizations l10n) {
    final payload = message.payload;
    final amount = payload['amount'];
    final money = amount is num ? Formatters.money(amount) : '';
    final byBuyer = payload['by'] == 'BUYER';
    final who = byBuyer == viewerIsBuyer
        ? l10n.offerCardWhoYou
        : byBuyer
            ? l10n.offerCardWhoBuyer
            : l10n.offerCardWhoSeller;
    return switch (payload['kind']) {
      'OFFER_RECEIVED' => l10n.offerCardOffered(who, money),
      'OFFER_COUNTERED' => l10n.offerCardCountered(who, money),
      'OFFER_ACCEPTED' => l10n.offerCardAccepted(who, money),
      'OFFER_REJECTED' => l10n.offerCardDeclined(who, money),
      'OFFER_WITHDRAWN' => l10n.offerCardWithdrawn,
      'NEGOTIATION_CANCELLED' => l10n.offerCardEnded,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isListing = message.type == ChatMessageType.listingContext;
    final negotiationId = message.payload['negotiationId'] as String?;
    final offerText = message.type == ChatMessageType.offerEvent ? _offerText(l10n) : null;
    final onOpenOffer = offerText != null && negotiationId != null && onOpenNegotiation != null
        ? () => onOpenNegotiation!(negotiationId)
        : null;
    final title = message.payload['title'] as String? ?? '';
    final price = message.payload['price'];
    final label = isListing
        ? l10n.chatListingCardLabel(title)
        : offerText != null
            ? (onOpenOffer == null ? offerText : '$offerText. ${l10n.offerCardView}')
            : l10n.chatCardUpdate;
    final onTap = isListing ? onOpenListing : onOpenOffer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Semantics(
          container: true,
          button: onTap != null,
          label: label,
          excludeSemantics: true,
          onTap: onTap,
          child: Material(
            color: AppColors.brandSurfaceTint,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.86,
                  minHeight: AppSizes.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: isListing
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardTitle
                                  .copyWith(color: AppColors.brandForeground),
                            ),
                            if (price is num)
                              Text(
                                Formatters.currency(price),
                                style:
                                    AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                              ),
                          ],
                        )
                      : offerText != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  offerText,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.cardTitle
                                      .copyWith(color: AppColors.brandForeground),
                                ),
                                if (onOpenOffer != null)
                                  Text(
                                    l10n.offerCardView,
                                    style: AppTextStyles.linkSmall,
                                  ),
                              ],
                            )
                          : Text(
                              l10n.chatCardUpdate,
                              textAlign: TextAlign.center,
                              style:
                                  AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                            ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
