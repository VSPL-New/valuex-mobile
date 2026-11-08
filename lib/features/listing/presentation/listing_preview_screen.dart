import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import 'listing_error_messages.dart';
import 'providers/listing_preview_providers.dart';
import 'widgets/listing_preview.dart';

/// The owner's read-only preview of a saved listing (US-123). The listing is loaded by id every time
/// the screen opens, so a stale card or a copied link never decides who may see it.
class ListingPreviewScreen extends ConsumerWidget {
  final String listingId;

  const ListingPreviewScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preview = ref.watch(listingPreviewProvider(listingId));
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.myListings),
          ),
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
      ),
    );
  }

  static String _message(AppLocalizations l10n, Object error) =>
      error is ApiError && error.code == 'LISTING_NOT_FOUND'
          ? l10n.notifListingNotFound
          : listingErrorMessage(l10n, error);
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            SquareBackButton(onPressed: onBack),
            const SizedBox(width: AppSpacing.md),
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
          ],
        ),
      ),
    );
  }
}
