import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/widgets/chat_time.dart';
import '../../domain/negotiation.dart';
import '../../domain/offers.dart';
import '../negotiation_format.dart';
import 'countdown_text.dart';
import 'expiry_chip.dart';

/// One offer on the Offers screen (US-076): the other person (with a rating chip for a buyer), the
/// item, "Offered ₹12,000 of ₹14,500", when it was made, where it stands and, while an answer is
/// awaited, a countdown. The row is spoken as one sentence and opens the negotiation.
class OfferCardTile extends StatelessWidget {
  final OfferCard card;
  final OffersSide side;
  final DateTime now;
  final VoidCallback onTap;

  const OfferCardTile({
    super.key,
    required this.card,
    required this.side,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offered = Formatters.money(card.offeredPrice);
    final asking = Formatters.money(card.askingPrice);
    final ago = chatAgo(context, card.offeredAt, now);
    final status = _status(l10n);
    return Semantics(
      button: true,
      label: [
        l10n.offersCardLabel(card.counterpartName, card.listingTitle, offered, asking, ago),
        if (status != null) status,
      ].join('. '),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(url: card.thumbnailUrl),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.counterpartName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardTitle
                                  .copyWith(color: AppColors.brandForeground),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            ago,
                            style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                          ),
                        ],
                      ),
                      if (side == OffersSide.received) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          card.counterpartRating == null
                              ? l10n.offersNoRatings
                              : l10n.offersRating(
                                  card.counterpartRating!.toStringAsFixed(1),
                                  card.counterpartRatingCount,
                                ),
                          style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        card.listingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.offersOfferedOf(offered, asking),
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.brandForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (status != null)
                            Text(
                              status,
                              style: AppTextStyles.caption.copyWith(
                                color: card.needsMyAnswer && !card.isPastExpiry
                                    ? AppColors.brandLink
                                    : AppColors.brandMutedText,
                                fontWeight: card.needsMyAnswer ? FontWeight.w600 : null,
                              ),
                            ),
                          if (card.state.isAwaitingAnswer && card.expiresAt != null)
                            ExpiryChip(expiresAt: card.expiresAt!, serverTime: card.serverTime),
                          if (card.state == NegotiationState.offerAccepted &&
                              card.priceLockExpiresAt != null)
                            _LockChip(lockEndsAt: card.priceLockExpiresAt!, card: card),
                        ],
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

  /// Where the offer stands, in words; null while an answer is awaited from nobody in particular.
  String? _status(AppLocalizations l10n) {
    if (card.isPastExpiry) return l10n.negotiationStatusExpired;
    return switch (card.state) {
      NegotiationState.sellerReviewing || NegotiationState.buyerReviewing => card.needsMyAnswer
          ? l10n.offersNeedsYourAnswer
          : (side == OffersSide.received ? l10n.offersWaitingBuyer : l10n.offersWaitingSeller),
      NegotiationState.offerAccepted =>
        l10n.negotiationStatusAccepted(Formatters.money(card.offeredPrice)),
      NegotiationState.offerRejected => l10n.negotiationStatusDeclined,
      NegotiationState.expired => l10n.negotiationStatusExpired,
      NegotiationState.cancelled => l10n.negotiationStatusCancelled,
      NegotiationState.converted => l10n.negotiationStatusConverted,
      NegotiationState.other => null,
    };
  }
}

class _LockChip extends StatelessWidget {
  final DateTime lockEndsAt;
  final OfferCard card;

  const _LockChip({required this.lockEndsAt, required this.card});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CountdownText(
      target: lockEndsAt,
      serverTime: card.serverTime,
      builder: (context, remaining) => Text(
        remaining == Duration.zero
            ? l10n.negotiationExpiredChip
            : l10n.offersLockEndsIn(durationLabel(l10n, remaining)),
        style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.brandSurfaceTint,
      child: const Icon(Icons.image_outlined, color: AppColors.brandMutedText),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => placeholder,
              ),
      ),
    );
  }
}
