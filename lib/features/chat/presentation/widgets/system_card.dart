import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../calls/domain/call_time.dart';
import '../../domain/chat.dart';

/// A card the system writes into the conversation. The listing card shows what the chat is about
/// at the moment it started; an offer card (US-017) says what happened in the negotiation and opens
/// it; a call card (US-014, US-015) says how a call went.
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
      'OFFER_SUPERSEDED' => l10n.offerCardSuperseded,
      'NEGOTIATION_CANCELLED' => l10n.offerCardEnded,
      _ => null,
    };
  }

  /// The line of a call card (US-014, US-015), or null when the card is not about a call. The caller
  /// is always the buyer, so the buyer sees "No answer" where the seller sees "Missed".
  String? _callText(AppLocalizations l10n) {
    if (message.type != ChatMessageType.callSummary) return null;
    final payload = message.payload;
    final kind = payload['type'] == 'VIDEO' ? l10n.callKindVideo : l10n.callKindVoice;
    final seconds = payload['durationSeconds'];
    final length = Duration(seconds: seconds is num ? seconds.toInt() : 0);
    return switch (payload['outcome']) {
      'COMPLETED' => l10n.callSummaryCompleted(kind, formatCallDuration(length)),
      'MISSED' => viewerIsBuyer ? l10n.callSummaryNoAnswer(kind) : l10n.callSummaryMissed(kind),
      'DECLINED' => l10n.callSummaryDeclined(kind),
      'FAILED' => l10n.callSummaryFailed(kind),
      _ => l10n.callSummaryInProgress(kind),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final callText = _callText(l10n);
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
            : callText ?? l10n.chatCardUpdate;
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
                              callText ?? l10n.chatCardUpdate,
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
