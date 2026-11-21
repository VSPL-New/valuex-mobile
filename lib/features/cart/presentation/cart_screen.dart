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
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../domain/cart.dart';
import 'cart_error_messages.dart';
import 'providers/cart_providers.dart';
import 'widgets/cart_line_card.dart';

/// The buyer's cart (US-019): the items they hold at an agreed price, grouped by seller with a
/// header for each seller, the total of what can be bought now and a checkout button that stays off
/// until checkout ships (US-021). Remove asks nothing: it shows an Undo that adds the item back while
/// its price still stands. Pull down to read the cart again.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, CartLine line) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // The Undo button can be pressed after this screen is gone, so it uses the container, not `ref`.
    final container = ProviderScope.containerOf(context);
    try {
      await ref.read(cartProvider.notifier).remove(line.itemId);
    } on Object catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(cartErrorMessage(l10n, error))));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.cartRemoved),
          action: SnackBarAction(
            label: l10n.cartUndo,
            onPressed: () => unawaited(_undo(messenger, l10n, container, line)),
          ),
        ),
      );
  }

  /// Puts the item back. It works only while the price still stands; a refusal says why.
  Future<void> _undo(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    ProviderContainer container,
    CartLine line,
  ) async {
    final result = await container.read(cartAdderProvider.notifier).add(line.listingId);
    final error = result.error;
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(cartErrorMessage(l10n, error))));
    }
    await container.read(cartProvider.notifier).refreshQuietly();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cart = ref.watch(cartProvider);
    final data = cart.value;
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(count: data?.itemCount, onBack: () => _back(context)),
          Expanded(
            child: data != null
                ? _Content(
                    data: data,
                    onRefresh: () => _refresh(context, ref),
                    onRemove: (line) => unawaited(_remove(context, ref, line)),
                  )
                : cart.hasError
                    ? ErrorView(
                        message: cartErrorMessage(l10n, cart.error!),
                        onRetry: () => ref.invalidate(cartProvider),
                      )
                    : const LoadingIndicator(),
          ),
          if (data != null && !data.isEmpty) _Footer(data: data),
        ],
      ),
    );
  }

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(RouteNames.home);

  /// Pull to refresh. A failed read keeps what the cart held and says so.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).cartRefreshFailed;
    try {
      await ref.read(cartProvider.notifier).refresh();
      ref.invalidate(homeBadgesProvider);
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _Header extends StatelessWidget {
  final int? count;
  final VoidCallback onBack;

  const _Header({required this.count, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.brandSurface),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              SquareBackButton(onPressed: onBack),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.cartTitle, style: AppTextStyles.heading2),
                ),
              ),
              if (count != null && count! > 0)
                Text(l10n.cartItemsCount(count!), style: AppTextStyles.hint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final CartData data;
  final Future<void> Function() onRefresh;
  final void Function(CartLine line) onRemove;

  const _Content({required this.data, required this.onRefresh, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: data.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_Empty(title: l10n.cartEmptyTitle, body: l10n.cartEmptyBody)],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final group in data.groups) ...[
                  _SellerHeader(name: group.sellerName ?? l10n.cartSellerFallback),
                  for (final line in group.items) ...[
                    CartLineCard(
                      key: ValueKey(line.itemId),
                      line: line,
                      sellerName: group.sellerName ?? l10n.cartSellerFallback,
                      serverTime: data.serverTime,
                      onRemove: () => onRemove(line),
                      onChooseDelivery: line.status.payable
                          ? () => unawaited(context.push(RouteNames.cartDelivery(line.itemId)))
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _SellerHeader extends StatelessWidget {
  final String name;

  const _SellerHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.storefront_outlined, size: 18, color: AppColors.brandMutedText),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String body;

  const _Empty({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const ExcludeSemantics(
            child: Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.brandMutedText),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.sectionTitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTextStyles.hint, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// The total of what can be bought now and the checkout button, which stays off until US-021.
class _Footer extends StatelessWidget {
  final CartData data;

  const _Footer({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Semantics(
                container: true,
                label: '${l10n.cartTotal}, ${Formatters.money(data.payableTotal)}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.cartTotal, style: AppTextStyles.sectionTitle)),
                    Text(
                      Formatters.money(data.payableTotal),
                      style: AppTextStyles.cardPrice.copyWith(color: AppColors.brandForeground),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              BrandGradientButton(label: l10n.cartProceed, onPressed: null),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.cartCheckoutSoon,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
