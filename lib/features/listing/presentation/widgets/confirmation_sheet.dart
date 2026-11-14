import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Asks the seller to confirm in a bottom sheet (US-010: deleting a listing, and sending a major
/// edit back to review). True when they confirm; Cancel, a swipe down or a tap outside is false.
Future<bool> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required List<Widget> body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => _ConfirmationSheet(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return confirmed ?? false;
}

class _ConfirmationSheet extends StatelessWidget {
  final String title;
  final List<Widget> body;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const _ConfirmationSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: AppTextStyles.heading2)),
            const SizedBox(height: AppSpacing.sm),
            ...body,
            const SizedBox(height: AppSpacing.lg),
            if (destructive)
              _DestructiveButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              )
            else
              BrandGradientButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: cancelLabel,
              isOutlined: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid red action: the brand gradient is for going forward, not for deleting.
class _DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DestructiveButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    return Material(
      color: AppColors.brandError,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.buttonMedium,
            minWidth: double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Center(
              child: Text(label, textAlign: TextAlign.center, style: AppTextStyles.button),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet that asks the seller to confirm deleting [title]; the plan fee is not refunded.
Future<bool> showDeleteListingSheet(BuildContext context, String title) {
  final l10n = AppLocalizations.of(context);
  return showConfirmationSheet(
    context,
    title: l10n.myListingsDeleteTitle,
    body: [Text(l10n.myListingsDeleteBody(title), style: AppTextStyles.body)],
    confirmLabel: l10n.myListingsDeleteConfirm,
    cancelLabel: l10n.commonCancel,
    destructive: true,
  );
}

/// The sheet that asks the owner to confirm marking [title] Sold, Rented or Leased (US-118). It
/// says the deal may have been made outside JustQlic, and that this cannot be undone.
Future<bool> showCloseListingSheet(BuildContext context, String title, String outcome) {
  final l10n = AppLocalizations.of(context);
  return showConfirmationSheet(
    context,
    title: l10n.myListingsCloseTitle(outcome),
    body: [Text(l10n.myListingsCloseBody(title), style: AppTextStyles.body)],
    confirmLabel: l10n.myListingsCloseConfirm(outcome),
    cancelLabel: l10n.commonCancel,
  );
}
