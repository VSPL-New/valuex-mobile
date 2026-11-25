import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/public_listing.dart';

/// Chat, Call, Video, Make an Offer and Buy Now, exactly as the server allows them for this buyer
/// (US-012, US-069, US-014, US-015). Chat opens the conversation; Call and Video ring the seller.
/// One the server marks not applicable is left out. Add to Cart is not here: it is offered on the
/// accepted offer, in the chat and on the negotiation screen (US-019).
class ListingActions extends StatelessWidget {
  final Capabilities capabilities;
  final VoidCallback onUnbuilt;
  final VoidCallback onChat;

  /// Opens the Make Offer sheet, or the negotiation the buyer already has (US-017); an older caller
  /// that does not pass it keeps the coming soon message.
  final VoidCallback? onOffer;

  /// Reserves the listing at its asking price (US-068); an older caller that does not pass it keeps the
  /// coming soon message.
  final VoidCallback? onBuyNow;

  /// A Buy Now is being started; a second tap is ignored until it answers.
  final bool buyNowBusy;

  /// The buyer already has an open negotiation here, so the button reads "View offer".
  final bool hasOffer;

  /// The buyer already has a chat about this listing; the button opens it and still reads "Chat".
  final bool hasChat;

  /// A chat is being opened; a second tap is ignored until it answers.
  final bool chatBusy;

  /// Rings the seller by voice (US-014); an older caller that does not pass it keeps the coming soon
  /// message.
  final VoidCallback? onCall;

  /// Rings the seller with video (US-015); an older caller that does not pass it keeps the coming
  /// soon message.
  final VoidCallback? onVideo;

  /// A call is being started; a second tap on Call or Video is ignored until it answers.
  final bool callBusy;

  const ListingActions({
    super.key,
    required this.capabilities,
    required this.onUnbuilt,
    required this.onChat,
    this.onCall,
    this.onVideo,
    this.callBusy = false,
    this.onOffer,
    this.onBuyNow,
    this.buyNowBusy = false,
    this.hasOffer = false,
    this.hasChat = false,
    this.chatBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contact = [
      (
        hasChat ? l10n.contactOpenChat : l10n.previewChat,
        capabilities.chat,
        Icons.chat_bubble_outline_rounded,
        chatBusy ? null : onChat,
      ),
      (
        l10n.previewCall,
        capabilities.call,
        Icons.call_outlined,
        callBusy ? null : (onCall ?? onUnbuilt),
      ),
      (
        l10n.previewVideo,
        capabilities.video,
        Icons.videocam_outlined,
        callBusy ? null : (onVideo ?? onUnbuilt),
      ),
    ].where((entry) => !entry.$2.hidden).toList();
    final commerce = [
      (
        hasOffer ? l10n.listingViewViewOffer : l10n.previewMakeOffer,
        capabilities.offer,
        false,
        onOffer ?? onUnbuilt,
      ),
      (
        l10n.previewBuyNow,
        capabilities.buyNow,
        true,
        buyNowBusy ? null : (onBuyNow ?? onUnbuilt),
      ),
    ].where((entry) => !entry.$2.hidden).toList();
    if (contact.isEmpty && commerce.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brandSurface,
        border: Border(top: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (contact.isNotEmpty)
                _row([
                  for (final (label, capability, icon, onTap) in contact)
                    _Action(
                      label: label,
                      capability: capability,
                      onTap: onTap,
                      builder: (text, onPressed) =>
                          SingleToneButton(label: text, onPressed: onPressed, leadingIcon: icon),
                    ),
                ], gap: AppSpacing.sm),
              if (contact.isNotEmpty && commerce.isNotEmpty) const SizedBox(height: AppSpacing.sm),
              if (commerce.isNotEmpty)
                _row([
                  for (final (label, capability, primary, onTap) in commerce)
                    _Action(
                      label: label,
                      capability: capability,
                      onTap: onTap,
                      builder: (text, onPressed) => primary
                          ? BrandGradientButton(
                              label: text,
                              onPressed: onPressed,
                              trailingIcon: Icons.chevron_right_rounded,
                            )
                          : SingleToneButton(label: text, onPressed: onPressed),
                    ),
                ], gap: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _row(List<Widget> children, {required double gap}) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: children[i]),
            ],
          ],
        ),
      );
}

class _Action extends StatelessWidget {
  final String label;
  final Capability capability;

  /// What a tap does when the server offers the action; null while it must be ignored.
  final VoidCallback? onTap;
  final Widget Function(String text, VoidCallback? onPressed) builder;

  const _Action({
    required this.label,
    required this.capability,
    required this.onTap,
    required this.builder,
  });

  String _status(AppLocalizations l10n) => switch (capability.reason) {
        CapabilityReason.ownListing => l10n.listingViewOwnListing,
        CapabilityReason.unavailable => l10n.listingViewUnavailable,
        CapabilityReason.notNegotiable => l10n.listingViewNotNegotiable,
        CapabilityReason.identityRequired => l10n.listingViewIdentityRequired,
        CapabilityReason.reserved => l10n.listingViewReserved,
        CapabilityReason.disabledBySeller => l10n.listingViewBuyNowOff,
        _ => l10n.listingViewComingSoon,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _status(l10n);
    final onPressed = capability.available ? onTap : null;
    // Disabled buttons stay quiet on screen; the reason is only spoken, except for your own listing.
    final showStatus = !capability.available && capability.reason == CapabilityReason.ownListing;
    return Semantics(
      container: true,
      enabled: onPressed != null,
      label: capability.available ? label : l10n.listingViewActionLabel(label, status),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          builder(label, onPressed),
          if (showStatus)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
              ),
            ),
        ],
      ),
    );
  }
}
