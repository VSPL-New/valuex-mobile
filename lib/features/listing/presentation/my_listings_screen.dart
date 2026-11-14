import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/presentation/notification_navigation.dart';
import '../data/listing_repository.dart';
import '../domain/my_listings.dart';
import 'listing_error_messages.dart';
import 'providers/item_details_controller.dart';
import 'providers/my_listings_controller.dart';
import 'widgets/confirmation_sheet.dart';
import 'widgets/my_listing_card.dart';
import 'widgets/my_listings_summary_cards.dart';
import 'widgets/option_chip.dart';
import 'widgets/listing_status_badge.dart';

/// My Listings (US-010): the seller's own listings with counts, All / Active / Sold filters, and
/// per listing a way to open it, edit it and delete it (with a five second undo).
class MyListingsScreen extends ConsumerStatefulWidget {
  /// How long the seller can undo a delete before it is sent to the server.
  static const Duration undoWindow = Duration(seconds: 5);

  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  /// Listings that are drafts or waiting for a plan: opened for the next step, not edited.
  static const Set<String> _planStatuses = {'PLAN_SELECTION_PENDING', 'PLAN_PAYMENT_FAILED'};

  MyListingsController get _controller => ref.read(myListingsControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _controller.load(filter: MyListingsFilter.all));
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(MyListingItem item) async {
    final l10n = AppLocalizations.of(context);
    if (item.isSold) {
      _say(l10n.myListingsSaleDetailsSoon);
    } else if (item.canEdit || _planStatuses.contains(item.status)) {
      await _edit(item);
    } else {
      await context.push<void>(RouteNames.listingPreview(item.id));
    }
  }

  /// Loads the listing, because Item Details and plan selection both need what is stored.
  Future<void> _edit(MyListingItem item) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final controller = _controller;
    try {
      final listing = await ref.read(listingRepositoryProvider).getListing(item.id);
      if (!mounted) return;
      final isPlan = _planStatuses.contains(listing.status);
      await router.push<void>(
        isPlan ? RouteNames.sellPlan : RouteNames.sellDetails,
        extra: isPlan
            ? planArgsFor(listing, l10n)
            : ItemDetailsArgs(listingId: listing.listingId, existing: listing),
      );
      unawaited(controller.load());
    } on ApiError catch (error) {
      if (mounted) _say(listingErrorMessage(l10n, error));
    }
  }

  /// Asks first, then hides the listing for the undo window. The delete is sent only when the
  /// snackbar closes without Undo.
  Future<void> _delete(MyListingItem item) async {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    final messenger = ScaffoldMessenger.of(context);
    final title = item.title.isEmpty ? l10n.myListingsUntitled : item.title;
    if (!await showDeleteListingSheet(context, title) || !mounted) return;

    controller.hide(item.id);
    final reason = await messenger
        .showSnackBar(
          SnackBar(
            content: Text(l10n.myListingsDeleted),
            duration: MyListingsScreen.undoWindow,
            // A snackbar with an action stays until dismissed unless told otherwise; the delete
            // must go out when the window closes.
            persist: false,
            action: SnackBarAction(label: l10n.myListingsUndo, onPressed: () {}),
          ),
        )
        .closed;
    if (reason == SnackBarClosedReason.action) {
      controller.restore(item.id);
      return;
    }
    final error = await controller.commitDelete(item.id);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(listingErrorMessage(l10n, error))));
    }
  }

  /// Asks first, then marks the property Sold, Rented or Leased (US-118). The page reloads on success
  /// so the card shows its new status.
  Future<void> _close(MyListingItem item) async {
    final outcome = item.closeOutcome;
    if (outcome == null) return;
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    final title = item.title.isEmpty ? l10n.myListingsUntitled : item.title;
    final label = closedOutcomeLabel(l10n, outcome);
    if (!await showCloseListingSheet(context, title, label) || !mounted) return;
    final error = await controller.close(item.id, outcome);
    if (!mounted) return;
    _say(error == null ? l10n.myListingsClosed(label) : listingErrorMessage(l10n, error));
  }

  Future<void> _loadMore() async {
    final error = await _controller.loadMore();
    if (error != null && mounted) {
      _say(listingErrorMessage(AppLocalizations.of(context), error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(myListingsControllerProvider);
    final loaded = state.error == null && !(state.isLoading && state.items.isEmpty);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            subtitle: loaded ? l10n.myListingsTotal(state.summary.total) : null,
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.profile),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (loaded) ...[
                    MyListingsSummaryCards(summary: state.summary),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _Filters(selected: state.filter, onSelected: (f) => _controller.load(filter: f)),
                  const SizedBox(height: AppSpacing.sm),
                  ..._content(l10n, state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(AppLocalizations l10n, MyListingsState state) {
    final items = state.visibleItems;
    if (state.isLoading && state.items.isEmpty) {
      return const [Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LoadingIndicator())];
    }
    final error = state.error;
    if (error != null && state.items.isEmpty) {
      return [
        ErrorView(message: listingErrorMessage(l10n, error), onRetry: () => _controller.load()),
      ];
    }
    if (items.isEmpty) return [_EmptyState(filter: state.filter)];
    return [
      for (final item in items) ...[
        MyListingCard(
          item: item,
          onOpen: () => unawaited(_open(item)),
          onPreview: () => unawaited(context.push<void>(RouteNames.listingPreview(item.id))),
          onEdit: item.canEdit ? () => unawaited(_edit(item)) : null,
          onDelete: item.canDelete ? () => unawaited(_delete(item)) : null,
          onClose: item.closeOutcome == null ? null : () => unawaited(_close(item)),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (state.hasNext)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppButton(
            label: l10n.myListingsLoadMore,
            isOutlined: true,
            isLoading: state.isLoadingMore,
            onPressed: () => unawaited(_loadMore()),
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  final String? subtitle;
  final VoidCallback onBack;

  const _Header({required this.subtitle, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SquareBackButton(onPressed: onBack),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                  header: true, child: Text(l10n.myListingsTitle, style: AppTextStyles.heading2)),
              if (subtitle != null) Text(subtitle!, style: AppTextStyles.hint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final MyListingsFilter selected;
  final ValueChanged<MyListingsFilter> onSelected;

  const _Filters({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(MyListingsFilter filter) => switch (filter) {
          MyListingsFilter.all => l10n.myListingsFilterAll,
          MyListingsFilter.active => l10n.myListingsFilterActive,
          MyListingsFilter.sold => l10n.myListingsFilterSold,
        };
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final filter in MyListingsFilter.values)
          OptionChip(
            label: label(filter),
            selected: filter == selected,
            onTap: () {
              if (filter != selected) onSelected(filter);
            },
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final MyListingsFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (filter) {
      MyListingsFilter.all => l10n.myListingsEmptyAll,
      MyListingsFilter.active => l10n.myListingsEmptyActive,
      MyListingsFilter.sold => l10n.myListingsEmptySold,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.brandMutedText),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
          if (filter == MyListingsFilter.all) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.myListingsListItem,
              onPressed: () => context.push(RouteNames.sell),
            ),
          ],
        ],
      ),
    );
  }
}
