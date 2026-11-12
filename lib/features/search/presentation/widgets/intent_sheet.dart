import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/transaction_intent.dart';
import '../search_labels.dart';

/// Buy, Rent or Lease for a Real Estate search (decision G3); null when the user closes it.
/// US-118 builds the full property flow on top of this.
Future<TransactionIntent?> showIntentSheet(BuildContext context) {
  return showModalBottomSheet<TransactionIntent>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => const IntentSheet(),
  );
}

class IntentSheet extends StatelessWidget {
  const IntentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.searchIntentTitle, style: AppTextStyles.heading2),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final intent in TransactionIntent.values)
            ListTile(
              minTileHeight: AppSizes.minTouchTarget,
              contentPadding: EdgeInsets.zero,
              title: Text(intentLabel(l10n, intent), style: AppTextStyles.body),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.brandMutedText),
              onTap: () => Navigator.of(context).pop(intent),
            ),
        ],
      ),
    );
  }
}
