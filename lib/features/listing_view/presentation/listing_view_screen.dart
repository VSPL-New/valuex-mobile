import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/main_nav.dart';
import 'listing_view_messages.dart';
import 'providers/listing_view_providers.dart';
import 'widgets/listing_actions.dart';
import 'widgets/listing_view_body.dart';

/// A buyer's view of one listing (US-012). It is loaded by id from the server on every open, so a
/// copied link or a stale card never decides what is shown.
class ListingViewScreen extends ConsumerWidget {
  /// Above this text scale the action area scrolls with the page instead of staying pinned.
  static const double _pinLimit = 1.3;

  final String listingId;

  const ListingViewScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listing = ref.watch(publicListingProvider(listingId));
    final large = MediaQuery.textScalerOf(context).scale(16) / 16 > _pinLimit;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  SquareBackButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.listingViewTitle, style: AppTextStyles.sectionTitle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: listing.when(
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                message: listingViewErrorMessage(l10n, error),
                onRetry: listingViewErrorFinal(error)
                    ? null
                    : () => ref.invalidate(publicListingProvider(listingId)),
              ),
              data: (data) {
                final body = ListingViewBody(
                  listing: data,
                  onRefreshPhotos: () => ref.invalidate(publicListingProvider(listingId)),
                  onOpenSeller: () => context.push(RouteNames.sellerProfile(data.seller.sellerId)),
                );
                final actions = ListingActions(
                  capabilities: data.capabilities,
                  onUnbuilt: () => showComingSoon(context),
                );
                if (large) {
                  return SingleChildScrollView(child: Column(children: [body, actions]));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Expanded(child: SingleChildScrollView(child: body)), actions],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
