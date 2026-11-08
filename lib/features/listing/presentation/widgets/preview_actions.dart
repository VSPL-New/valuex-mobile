import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';

/// The buyer actions as buyers will see them, switched off: the seller previews the page, so
/// nothing here starts a chat, call, offer or purchase. Each control says it is unavailable.
class PreviewActions extends StatelessWidget {
  const PreviewActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Row(
                children: [
                  const ExcludeSemantics(
                    child:
                        Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.brandMutedText),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(l10n.previewBuyerActionsUnavailable, style: AppTextStyles.hint),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _row([
                _off(l10n.previewChat, (label) => SingleToneButton(label: label, onPressed: null)),
                _off(l10n.previewCall, (label) => SingleToneButton(label: label, onPressed: null)),
                _off(l10n.previewVideo, (label) => SingleToneButton(label: label, onPressed: null)),
              ], gap: AppSpacing.sm),
              const SizedBox(height: AppSpacing.sm),
              _row([
                _off(l10n.previewMakeOffer,
                    (label) => SingleToneButton(label: label, onPressed: null)),
                _off(
                  l10n.previewBuyNow,
                  (label) => BrandGradientButton(
                    label: label,
                    onPressed: null,
                    trailingIcon: Icons.chevron_right_rounded,
                  ),
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

  /// A dimmed button that screen readers announce as a disabled button.
  static Widget _off(String label, Widget Function(String label) build) => Semantics(
        button: true,
        enabled: false,
        label: label,
        excludeSemantics: true,
        child: build(label),
      );
}
