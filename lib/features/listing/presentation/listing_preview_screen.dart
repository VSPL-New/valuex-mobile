import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import 'listing_error_messages.dart';
import 'providers/listing_preview_providers.dart';
import 'widgets/listing_preview.dart';

/// Opens the owner's preview of a saved listing as a popup over the current page, so closing it
/// returns to exactly where the seller was.
Future<void> showListingPreview(BuildContext context, String listingId) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.brandBackground,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: ListingPreviewScreen(listingId: listingId),
      ),
    ),
  );
}

/// The content of the owner's read-only preview popup (US-123). The listing is loaded by id every
/// time it opens, so a stale card or a copied link never decides who may see it.
class ListingPreviewScreen extends ConsumerWidget {
  final String listingId;

  const ListingPreviewScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preview = ref.watch(listingPreviewProvider(listingId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        Expanded(
          child: preview.when(
            loading: () => const LoadingIndicator(),
            error: (error, stack) => Center(
              child: ErrorView(
                message: _message(l10n, error),
                onRetry: () => ref.invalidate(listingPreviewProvider(listingId)),
              ),
            ),
            data: (data) => ListingPreview(
              data: data,
              onRetry: () => ref.invalidate(listingPreviewProvider(listingId)),
            ),
          ),
        ),
      ],
    );
  }

  static String _message(AppLocalizations l10n, Object error) =>
      error is ApiError && error.code == 'LISTING_NOT_FOUND'
          ? l10n.notifListingNotFound
          : listingErrorMessage(l10n, error);
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l10n.previewTitle, style: AppTextStyles.sectionTitle),
            ),
          ),
          Semantics(
            button: true,
            enabled: false,
            label: l10n.previewSaveUnavailable,
            excludeSemantics: true,
            child: const SizedBox(
              width: AppSizes.minTouchTarget,
              height: AppSizes.minTouchTarget,
              child: Opacity(
                opacity: 0.4,
                child: Icon(Icons.favorite_border_rounded, color: AppColors.brandForeground),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.brandForeground),
          ),
        ],
      ),
    );
  }
}
