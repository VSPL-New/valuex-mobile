import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/my_listings.dart';
import 'listing_status_badge.dart';

/// Tells the seller where a listing stands when it cannot be opened for editing: payment being
/// confirmed, under review, expired or rejected (US-010). It stands in for the read-only listing
/// page that US-123 adds.
Future<void> showListingStatusSheet(BuildContext context, MyListingItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => _StatusSheet(item: item),
  );
}

class _StatusSheet extends StatelessWidget {
  final MyListingItem item;

  const _StatusSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = item.title.isEmpty ? l10n.myListingsUntitled : item.title;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: AppTextStyles.heading2)),
            const SizedBox(height: AppSpacing.sm),
            Align(
                alignment: AlignmentDirectional.centerStart,
                child: ListingStatusBadge(badge: item.badge)),
            const SizedBox(height: AppSpacing.md),
            Text(listingStatusExplanation(l10n, item.badge), style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.commonClose,
              isOutlined: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
