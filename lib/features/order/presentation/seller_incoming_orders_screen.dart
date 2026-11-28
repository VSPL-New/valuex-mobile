import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/single_tone_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/main_nav.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/entities/incoming_order.dart';
import 'providers/seller_order_providers.dart';
import 'widgets/incoming_order_card.dart';
import 'widgets/incoming_orders_header.dart';
import 'widgets/order_count_tile.dart';
import 'widgets/order_status_chip.dart';

/// Seller Incoming Orders (US-112, Sprint 6 LLD A.8): every order placed on the seller's items,
/// grouped New, Packing, Scheduled and Shipped, with the buttons the server offers. Opened from the
/// Profile "Incoming Orders" row and from a new-order push.
class SellerIncomingOrdersScreen extends ConsumerStatefulWidget {
  const SellerIncomingOrdersScreen({super.key});

  @override
  ConsumerState<SellerIncomingOrdersScreen> createState() => _SellerIncomingOrdersScreenState();
}

class _SellerIncomingOrdersScreenState extends ConsumerState<SellerIncomingOrdersScreen> {
  /// How close to the end of the list the next page starts loading.
  static const double _loadMoreExtent = 400;

  final ScrollController _scroll = ScrollController();

  SellerOrdersController get _controller => ref.read(sellerOrdersControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(_controller.load);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < _loadMoreExtent) unawaited(_loadMore());
  }

  Future<void> _loadMore() async {
    final error = await _controller.loadMore();
    if (error != null && mounted) _say(apiErrorMessage(AppLocalizations.of(context), error));
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onAction(IncomingOrder order, SellerOrderAction action) async {
    switch (action) {
      case SellerOrderAction.startPacking:
        final error = await _controller.startPacking(order.id);
        _afterAction(error);
        if (error == null && mounted) await _openPacking(order);
      case SellerOrderAction.continuePacking:
        await _openPacking(order);
      case SellerOrderAction.markHandedOver:
        if (!await _confirmHandOver() || !mounted) return;
        _afterAction(await _controller.markHandedOver(order.id));
      case SellerOrderAction.viewPickupDetails:
        await _showPickupDetails(order);
      case SellerOrderAction.reject:
      case SellerOrderAction.schedulePickup:
      case SellerOrderAction.viewSchedule:
      case SellerOrderAction.reschedulePickup:
        // Reject is US-059 (Sprint 7); pickup scheduling is US-027.
        showComingSoon(context);
    }
  }

  /// Pack & Upload Proof (US-026). The list reloads on return; finishing packing says so, and the
  /// card then offers Schedule Pickup (US-027, plan G6).
  Future<void> _openPacking(IncomingOrder order) async {
    final done = await context.push<bool>(RouteNames.sellerOrderPacking(order.id));
    if (!mounted) return;
    unawaited(_controller.load());
    if (done ?? false) _say(AppLocalizations.of(context).packingDone);
  }

  /// The list has already reloaded; tells the seller why the action did not happen, and keeps the
  /// Profile badge in step.
  void _afterAction(ApiError? error) {
    ref.invalidate(profileMenuBadgesProvider);
    if (error == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    _say(switch (error.code) {
      'ERROR_ORDER_ACTION_NOT_ALLOWED' => l10n.sellerOrdersActionNotAllowed,
      'ERROR_ORDER_NOT_FOUND' => l10n.sellerOrdersNotFound,
      _ => apiErrorMessage(l10n, error),
    });
  }

  Future<bool> _confirmHandOver() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sellerOrdersHandOverQuestion, style: AppTextStyles.sectionTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sellerOrdersHandOverConfirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showPickupDetails(IncomingOrder order) {
    final l10n = AppLocalizations.of(context);
    final address = order.pickupAddress;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.sellerOrdersPickupDetailsTitle, style: AppTextStyles.sectionTitle),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.sellerOrdersPickupDetailsHint, style: AppTextStyles.hint),
              const SizedBox(height: AppSpacing.md),
              if (address != null)
                for (final line in address.lines) Text(line, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sellerOrdersControllerProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IncomingOrdersHeader(
            summary: state.loaded || state.items.isNotEmpty ? state.summary : null,
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.profile),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.load,
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: _content(l10n, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(AppLocalizations l10n, SellerOrdersState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const [Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LoadingIndicator())];
    }
    if (state.error != null && state.items.isEmpty) {
      return [ErrorView(message: l10n.sellerOrdersLoadFailed, onRetry: _controller.load)];
    }
    return [
      _Tiles(summary: state.summary),
      const SizedBox(height: AppSpacing.md),
      if (state.error != null) ...[
        _StaleBanner(onRetry: _controller.load),
        const SizedBox(height: AppSpacing.md),
      ],
      if (state.items.isEmpty) _EmptyState(message: l10n.sellerOrdersEmpty),
      for (final order in state.items) ...[
        IncomingOrderCard(
          key: ValueKey(order.id),
          order: order,
          busy: state.busyOrderId == order.id,
          onAction: (action) => unawaited(_onAction(order, action)),
          // Order details are US-023.
          onDetails: () => showComingSoon(context),
        ),
        const SizedBox(height: 12),
      ],
      if (state.isLoadingMore)
        const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LoadingIndicator()),
      if (state.items.isNotEmpty && !state.hasMore)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            l10n.sellerOrdersShowingAll(state.items.length),
            textAlign: TextAlign.center,
            style: AppTextStyles.hint,
          ),
        ),
    ];
  }
}

class _Tiles extends StatelessWidget {
  final OrdersSummary summary;

  const _Tiles({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(FulfilmentBucket bucket) => switch (bucket) {
          FulfilmentBucket.newOrder => l10n.sellerOrdersTileNew,
          FulfilmentBucket.packing => l10n.sellerOrdersTilePacking,
          FulfilmentBucket.scheduled => l10n.sellerOrdersTileScheduled,
          FulfilmentBucket.shipped => l10n.sellerOrdersTileShipped,
        };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bucket in FulfilmentBucket.values) ...[
          if (bucket != FulfilmentBucket.newOrder) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OrderCountTile(
              icon: bucketIcon(bucket),
              count: summary.count(bucket),
              label: label(bucket),
            ),
          ),
        ],
      ],
    );
  }
}

/// The last loaded list stays; this says it may be out of date and offers Retry.
class _StaleBanner extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _StaleBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        border: Border.all(color: AppColors.brandError),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(child: Icon(Icons.wifi_off, color: AppColors.brandError)),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.sellerOrdersLoadFailed, style: AppTextStyles.body)),
            ],
          ),
          const SizedBox(height: 12),
          SingleToneButton(label: l10n.commonRetry, leadingIcon: Icons.refresh, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.inbox_outlined, size: 48, color: AppColors.brandMutedText),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
