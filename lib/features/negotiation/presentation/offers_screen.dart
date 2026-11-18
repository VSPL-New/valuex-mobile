import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/offers.dart';
import 'providers/offers_controller.dart';
import 'widgets/offer_card_tile.dart';

/// The Offers screen (US-076, LLD J.7): the offers a person received as a seller and the ones they
/// sent as a buyer, each in three lists (Pending, Accepted, Closed). Pending offers come soonest
/// expiry first with a countdown, so the seller answers what is about to lapse. A card opens the
/// negotiation, where Accept, Reject and Counter are.
class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  OffersSide get _side => _tabs.index == 0 ? OffersSide.received : OffersSide.sent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(offersFilterProvider);
    final summary = ref.watch(offersSummaryProvider).value;
    final showReceivedCounts = _side == OffersSide.received && summary != null;
    String label(OffersFilter value, String text) {
      final count = !showReceivedCounts
          ? 0
          : switch (value) {
              OffersFilter.pending => summary.pending,
              OffersFilter.accepted => summary.accepted,
              OffersFilter.closed => 0,
            };
      return count > 0 ? '$text ($count)' : text;
    }

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        title: Text(l10n.offersTitle),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [Tab(text: l10n.offersTabReceived), Tab(text: l10n.offersTabSent)],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final (value, text) in [
                  (OffersFilter.pending, l10n.offersFilterPending),
                  (OffersFilter.accepted, l10n.offersFilterAccepted),
                  (OffersFilter.closed, l10n.offersFilterClosed),
                ])
                  ChoiceChip(
                    label: Text(label(value, text)),
                    selected: filter == value,
                    onSelected: (_) => ref.read(offersFilterProvider.notifier).select(value),
                  ),
              ],
            ),
          ),
          if (showReceivedCounts && summary.expiringSoon > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.offersExpiringSoon(summary.expiringSoon),
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandError),
                ),
              ),
            ),
          const Divider(height: 1, color: AppColors.brandBorder),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OffersList(query: (OffersSide.received, filter)),
                _OffersList(query: (OffersSide.sent, filter)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersList extends ConsumerWidget {
  final OffersQuery query;

  const _OffersList({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = offersListControllerProvider(query);
    final list = ref.watch(provider);
    return list.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => ErrorView(
        message: l10n.offersLoadFailed,
        onRetry: () => ref.invalidate(provider),
      ),
      data: (data) => _content(context, ref, data),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, OffersListState data) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(offersListControllerProvider(query).notifier);
    final (side, _) = query;

    Future<void> refresh() async {
      try {
        await controller.refresh();
        ref.invalidate(offersSummaryProvider);
      } on Object {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.offersLoadFailed)));
      }
    }

    if (data.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.offersEmptyTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.brandForeground),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              side == OffersSide.received ? l10n.offersEmptyReceivedHint : l10n.offersEmptySentHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandMutedText),
            ),
          ],
        ),
      );
    }
    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.items.length + (data.hasNext ? 1 : 0),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.brandBorder),
        itemBuilder: (context, index) {
          if (index == data.items.length) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: data.loadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : TextButton(
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: () async {
                          if (!await controller.loadMore()) {
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(l10n.offersLoadMoreFailed)));
                          }
                        },
                        child: Text(l10n.offersLoadMore),
                      ),
              ),
            );
          }
          final card = data.items[index];
          return OfferCardTile(
            card: card,
            side: side,
            now: now,
            onTap: () async {
              await context.push(RouteNames.negotiation(card.negotiationId));
              if (context.mounted) {
                ref
                  ..invalidate(offersListControllerProvider(query))
                  ..invalidate(offersSummaryProvider);
              }
            },
          );
        },
      ),
    );
  }
}
