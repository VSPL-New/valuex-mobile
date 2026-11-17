import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat.dart';

/// What the user chose on the blocked-message sheet.
enum BlockedMessageChoice { edit, deliver }

/// The alert for a message blocked for restricted terms (decision D13): the text with the terms
/// highlighted, and two choices. Returns null when the sheet is dismissed, which counts as Edit.
Future<BlockedMessageChoice?> showBlockedMessageSheet(
  BuildContext context, {
  required String text,
  required List<RestrictedTerm> terms,
}) {
  return showModalBottomSheet<BlockedMessageChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => BlockedMessageSheet(text: text, terms: terms),
  );
}

/// The content of the blocked-message sheet. Both actions are 48 dp or taller and work at large
/// text; the highlighted terms are announced as "restricted term".
class BlockedMessageSheet extends StatelessWidget {
  final String text;
  final List<RestrictedTerm> terms;

  const BlockedMessageSheet({super.key, required this.text, required this.terms});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
              header: true, child: Text(l10n.chatFlaggedTitle, style: AppTextStyles.heading2)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.brandBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.brandBorder),
            ),
            child: Text.rich(
              _highlighted(l10n.chatFlaggedTerm),
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.chatFlaggedAlert, style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.lg),
          BrandGradientButton(
            label: l10n.chatFlaggedEdit,
            onPressed: () => Navigator.of(context).pop(BlockedMessageChoice.edit),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleToneButton(
            label: l10n.chatFlaggedDeliver,
            onPressed: () => Navigator.of(context).pop(BlockedMessageChoice.deliver),
          ),
        ],
      ),
    );
  }

  /// The text with each restricted range marked and spoken as a restricted term.
  TextSpan _highlighted(String spokenLabel) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final term in terms) {
      if (term.start < at) continue;
      if (term.start > at) spans.add(TextSpan(text: text.substring(at, term.start)));
      spans.add(TextSpan(
        text: text.substring(term.start, term.end),
        semanticsLabel: '$spokenLabel: ${text.substring(term.start, term.end)}',
        style: const TextStyle(
          backgroundColor: AppColors.brandErrorTint,
          color: AppColors.brandError,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
      ));
      at = term.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return TextSpan(children: spans);
  }
}

/// Asks the sender to agree before a blocked message is delivered anyway (decision D13). Returns
/// true only for "I agree and deliver".
Future<bool> confirmPolicyAgreement(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final agreed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.chatAgreementTitle),
      content: Text(l10n.chatAgreementBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: AppColors.brandError,
          ),
          child: Text(l10n.chatAgreementAgree),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
