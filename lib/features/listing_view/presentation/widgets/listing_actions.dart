import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/public_listing.dart';

/// Chat, Call, Video, Add to Cart and Buy Now, exactly as the server allows them. None of them is
/// built yet, so an offered one only says so; one the server marks not applicable is left out.
class ListingActions extends StatelessWidget {
  final Capabilities capabilities;
  final VoidCallback onUnbuilt;

  const ListingActions({super.key, required this.capabilities, required this.onUnbuilt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contact = [
      (l10n.previewChat, capabilities.chat),
      (l10n.previewCall, capabilities.call),
      (l10n.previewVideo, capabilities.video),
    ].where((entry) => !entry.$2.hidden).toList();
    final commerce = [
      (l10n.listingViewAddToCart, capabilities.cart, false),
      (l10n.previewBuyNow, capabilities.buyNow, true),
    ].where((entry) => !entry.$2.hidden).toList();
    if (contact.isEmpty && commerce.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brandBackground,
        border: Border(top: BorderSide(color: AppColors.brandDivider)),
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
                  for (final (label, capability) in contact)
                    _Action(
                      label: label,
                      capability: capability,
                      onUnbuilt: onUnbuilt,
                      builder: (text, onPressed) =>
                          SingleToneButton(label: text, onPressed: onPressed),
                    ),
                ], gap: AppSpacing.sm),
              if (contact.isNotEmpty && commerce.isNotEmpty) const SizedBox(height: AppSpacing.sm),
              if (commerce.isNotEmpty)
                _row([
                  for (final (label, capability, primary) in commerce)
                    _Action(
                      label: label,
                      capability: capability,
                      onUnbuilt: onUnbuilt,
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
  final VoidCallback onUnbuilt;
  final Widget Function(String text, VoidCallback? onPressed) builder;

  const _Action({
    required this.label,
    required this.capability,
    required this.onUnbuilt,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = capability.reason == CapabilityReason.ownListing
        ? l10n.listingViewOwnListing
        : l10n.listingViewComingSoon;
    // An action the server offers has no flow behind it yet, so it only reports that.
    final onPressed = capability.available ? onUnbuilt : null;
    // Disabled buttons stay quiet on screen; the reason is only spoken, except for your own listing.
    final showStatus = onPressed == null && capability.reason == CapabilityReason.ownListing;
    return Semantics(
      container: true,
      enabled: onPressed != null,
      label: onPressed == null ? l10n.listingViewActionLabel(label, status) : label,
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
