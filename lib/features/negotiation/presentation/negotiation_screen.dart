import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/single_tone_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/presentation/add_accepted_to_cart.dart';
import '../domain/negotiation.dart';
import 'counter_sheet.dart';
import 'negotiation_error_messages.dart';
import 'negotiation_format.dart';
import 'providers/negotiation_controller.dart';
import 'widgets/expiry_chip.dart';
import 'widgets/offer_timeline.dart';
import 'widgets/price_lock_banner.dart';

/// One price negotiation, for the buyer and for the seller (US-017): the listing, where it stands
/// in one line, the countdown, every price put forward, and the actions the server allows right now.
/// The Proceed to checkout control belongs to the checkout stories (US-018, Sprint 5) and is not
/// shown here. Once the price is accepted the buyer can add the item to the cart from here (US-019).
class NegotiationScreen extends ConsumerStatefulWidget {
  final String negotiationId;

  const NegotiationScreen({super.key, required this.negotiationId});

  @override
  ConsumerState<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends ConsumerState<NegotiationScreen> {
  NegotiationController get _controller =>
      ref.read(negotiationControllerProvider(widget.negotiationId).notifier);

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows what went wrong, if anything; the screen already holds the latest state.
  void _report(Object? error) {
    if (error != null && mounted) {
      _say(negotiationErrorMessage(AppLocalizations.of(context), error));
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.negotiationKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return answer == true;
  }

  /// The seller confirms first: accepting locks the price for the buyer and, for goods, declines the
  /// other offers on the item (US-076). The buyer accepting a counter offer answers at once.
  Future<void> _accept(Negotiation negotiation) async {
    if (negotiation.role == NegotiationRole.seller) {
      final l10n = AppLocalizations.of(context);
      final sure = await _confirm(
        title: l10n.negotiationAcceptTitle,
        body: negotiation.listing.realEstate
            ? l10n.negotiationAcceptBodyProperty
            : l10n.negotiationAcceptBodyGoods,
        confirmLabel: l10n.negotiationAcceptConfirm,
      );
      if (!sure) return;
    }
    _report(await _controller.accept());
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    final sure = await _confirm(
      title: l10n.negotiationDeclineTitle,
      body: l10n.negotiationDeclineBody,
      confirmLabel: l10n.negotiationDecline,
    );
    if (sure) _report(await _controller.reject());
  }

  Future<void> _counter(CounterRange range) async {
    final amount = await showCounterSheet(context, range: range);
    if (amount != null) _report(await _controller.counter(amount));
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final sure = await _confirm(
      title: l10n.negotiationCancelTitle,
      body: l10n.negotiationCancelBody,
      confirmLabel: l10n.negotiationCancelOffer,
    );
    if (sure) _report(await _controller.cancel());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = negotiationControllerProvider(widget.negotiationId);
    final state = ref.watch(provider);
    final negotiation = state.value;
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        title: Text(l10n.negotiationTitle),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/')),
        actions: [
          if (negotiation?.threadId != null)
            IconButton(
              tooltip: l10n.offerChatWithSeller,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => context.push(RouteNames.chatThread(negotiation!.threadId!)),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => ErrorView(
          message: negotiationErrorMessage(l10n, error),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (data) => _body(context, data),
      ),
    );
  }

  Widget _body(BuildContext context, Negotiation negotiation) {
    final l10n = AppLocalizations.of(context);
    final actions = negotiation.actions;
    final pending = negotiation.pendingOffer;
    final lockShown =
        negotiation.state == NegotiationState.offerAccepted && negotiation.agreedPrice != null;
    final showExpiry = negotiation.state.isAwaitingAnswer && negotiation.expiresAt != null;
    // At the last round the counter is gone and only Accept and Decline remain (US-076).
    final roundCapReached = negotiation.isMyTurn &&
        !actions.canCounter &&
        actions.canAccept &&
        negotiation.maxRounds > 0 &&
        negotiation.round >= negotiation.maxRounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ListingHeader(
                  negotiation: negotiation,
                  onOpen: () => context.push(RouteNames.listingView(negotiation.listing.listingId)),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    negotiationStatusText(l10n, negotiation),
                    style: AppTextStyles.heading2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.negotiationRound(negotiation.round, negotiation.maxRounds),
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                    ),
                    if (showExpiry)
                      ExpiryChip(
                        expiresAt: negotiation.expiresAt!,
                        serverTime: negotiation.serverTime,
                      ),
                  ],
                ),
                if (lockShown) ...[
                  const SizedBox(height: AppSpacing.md),
                  PriceLockBanner(
                    agreedPrice: negotiation.agreedPrice!,
                    lockEndsAt: negotiation.priceLockExpiresAt,
                    serverTime: negotiation.serverTime,
                  ),
                  if (negotiation.role == NegotiationRole.buyer && !negotiation.listing.realEstate)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: SingleToneButton(
                        label: l10n.offerCardAddToCart,
                        onPressed: () => unawaited(
                          addAcceptedToCart(context, ref, negotiation.listing.listingId),
                        ),
                      ),
                    ),
                  if (negotiation.role == NegotiationRole.seller && !negotiation.listing.realEstate)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        l10n.negotiationSellerAcceptedNote,
                        style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                      ),
                    ),
                ],
                if (roundCapReached) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.negotiationRoundCap,
                      style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandMutedText),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.negotiationOffersHeading, style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                OfferTimeline(offers: negotiation.offers, viewer: negotiation.role),
              ],
            ),
          ),
        ),
        if (actions.canAccept || actions.canCounter || actions.canReject || actions.canCancel)
          _ActionBar(
            children: [
              if (actions.canAccept && pending != null)
                BrandGradientButton(
                  label: l10n.negotiationAcceptAmount(Formatters.money(pending.amount)),
                  onPressed: () => _accept(negotiation),
                ),
              if (actions.canCounter && negotiation.counterRange != null)
                SingleToneButton(
                  label: l10n.negotiationCounter,
                  onPressed: () => _counter(negotiation.counterRange!),
                ),
              if (actions.canReject)
                SingleToneButton(label: l10n.negotiationDecline, onPressed: _reject),
              if (actions.canCancel)
                SingleToneButton(label: l10n.negotiationCancelOffer, onPressed: _cancel),
            ],
          ),
      ],
    );
  }
}

class _ListingHeader extends StatelessWidget {
  final Negotiation negotiation;
  final VoidCallback onOpen;

  const _ListingHeader({required this.negotiation, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listing = negotiation.listing;
    return Semantics(
      button: true,
      label: '${listing.title}, ${l10n.negotiationAsking(Formatters.money(listing.askingPrice))}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.negotiationAsking(Formatters.money(listing.askingPrice)),
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    negotiation.counterpart.displayName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final List<Widget> children;

  const _ActionBar({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brandSurface,
        border: Border(top: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
