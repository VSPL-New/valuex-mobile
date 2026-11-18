import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../buy_now/presentation/buy_now_error_messages.dart';
import '../../buy_now/presentation/providers/buy_now_launcher.dart';
import '../../chat/presentation/contact_error_messages.dart';
import '../../chat/presentation/providers/chat_launcher.dart';
import '../../home/presentation/main_nav.dart';
import '../../negotiation/presentation/offer_sheet.dart';
import '../../saved_listings/presentation/widgets/save_heart.dart';
import '../domain/public_listing.dart';
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

  /// Opens the chat about the listing (US-069): straight to an existing one, otherwise the server
  /// starts it. A refusal shows its message; a listing that is gone refreshes the page.
  Future<void> _openChat(BuildContext context, WidgetRef ref, PublicListing listing) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(chatLauncherProvider.notifier)
        .open(listing.listingId, knownThreadId: listing.chatThreadId);
    if (!context.mounted) return;
    final threadId = result.threadId;
    if (threadId != null) {
      await context.push(RouteNames.chatThread(threadId));
      if (context.mounted) ref.invalidate(publicListingProvider(listingId));
      return;
    }
    final error = result.error;
    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(contactErrorMessage(l10n, error))));
    if (error is ApiError && error.code == 'ERROR_LISTING_NOT_AVAILABLE') {
      ref.invalidate(publicListingProvider(listingId));
    }
  }

  /// Make an Offer (US-017): opens the negotiation the buyer already has, otherwise the offer
  /// sheet; a negotiation that was made, or already existed, is then shown. The page is read
  /// again afterwards because the offer changes what the buyer can do here.
  Future<void> _makeOffer(BuildContext context, WidgetRef ref, PublicListing listing) async {
    final existing = listing.negotiationId;
    final price = listing.price;
    String? negotiationId = existing;
    if (negotiationId == null) {
      if (price == null) return;
      negotiationId = await showOfferSheet(
        context,
        listingId: listing.listingId,
        askingPrice: price,
        onChat: () {
          Navigator.of(context).pop();
          _openChat(context, ref, listing);
        },
      );
    }
    if (negotiationId == null || !context.mounted) return;
    await context.push(RouteNames.negotiation(negotiationId));
    if (context.mounted) ref.invalidate(publicListingProvider(listingId));
  }

  /// Buy Now (US-068): reserves the listing at the price the buyer saw. A refusal shows its message,
  /// and the page is read again when what the buyer saw is no longer true (sold, reserved, price
  /// changed, switched off). The reservation then goes to checkout, which arrives with Sprint 5.
  Future<void> _buyNow(BuildContext context, WidgetRef ref, PublicListing listing) async {
    final price = listing.price;
    if (price == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(buyNowLauncherProvider.notifier).start(
          listing.listingId,
          expectedPrice: price.toString(),
          clientRequestId: const Uuid().v4(),
        );
    if (!context.mounted) return;
    final error = result.error;
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(buyNowErrorMessage(l10n, error))));
      if (buyNowErrorStalesPage(error)) ref.invalidate(publicListingProvider(listingId));
      return;
    }
    if (result.reservation == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.buyNowReserved)));
    ref.invalidate(publicListingProvider(listingId));
  }

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
                  if (listing.value case final data?)
                    SaveHeart(listingId: data.listingId, saved: data.saved, overPhoto: false),
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
                  hasChat: data.chatThreadId != null,
                  chatBusy: ref.watch(chatLauncherProvider),
                  onChat: () => _openChat(context, ref, data),
                  onOffer: () => _makeOffer(context, ref, data),
                  onBuyNow: () => _buyNow(context, ref, data),
                  buyNowBusy: ref.watch(buyNowLauncherProvider),
                  hasOffer: data.negotiationId != null,
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
