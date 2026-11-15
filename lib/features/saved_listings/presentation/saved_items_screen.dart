import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/domain/entities/listing.dart';
import '../../home/presentation/home_labels.dart';
import '../../home/presentation/main_nav.dart';
import '../domain/saved_listing.dart';
import 'providers/saved_items_controller.dart';

/// Saved Items (US-073): the listings the buyer saved, newest first. One that is no longer for sale
/// stays in the list, greyed and marked, and can only be removed; one that is only hidden for a
/// check says so and comes back by itself.
class SavedItemsScreen extends ConsumerStatefulWidget {
  /// Loads the next page when the list is this close to its end.
  static const double _loadMoreDistance = 240;

  const SavedItemsScreen({super.key});

  @override
  ConsumerState<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends ConsumerState<SavedItemsScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < SavedItemsScreen._loadMoreDistance) _loadMore();
  }

  Future<void> _loadMore() async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).savedItemsLoadMoreFailed;
    final ok = await ref.read(savedItemsControllerProvider.notifier).loadMore();
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _remove(SavedListing item) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).savedItemRemoveFailed;
    final ok = await ref.read(savedItemsControllerProvider.notifier).remove(item.id);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(savedItemsControllerProvider);
    try {
      await ref.read(savedItemsControllerProvider.future);
    } on Object {
      // The error is shown in place; the spinner just stops.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(savedItemsControllerProvider);
    final saved = async.value;

    final Widget body;
    if (saved == null && async.hasError) {
      body = ErrorView(
        message: l10n.savedItemsLoadFailed,
        onRetry: () => ref.invalidate(savedItemsControllerProvider),
      );
    } else if (saved == null) {
      body = const LoadingIndicator();
    } else if (saved.items.isEmpty) {
      body = RefreshIndicator(onRefresh: _refresh, child: const _EmptyState());
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: saved.items.length + (saved.loadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= saved.items.length) return const LoadingIndicator();
            final item = saved.items[index];
            return _SavedItemCard(
              item: item,
              onOpen: () => context.push(RouteNames.listingView(item.id)),
              onRemove: () => _remove(item),
              onUnbuilt: () => showComingSoon(context),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: SquareBackButton(
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go(RouteNames.profile),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.savedItemsTitle, style: AppTextStyles.heading2),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.favorite_border, size: 48, color: AppColors.brandMutedText),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.savedItemsEmpty, style: AppTextStyles.body, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.savedItemsEmptyHint,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final SavedListing item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onUnbuilt;

  const _SavedItemCard({
    required this.item,
    required this.onOpen,
    required this.onRemove,
    required this.onUnbuilt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final price = item.price == null ? null : Formatters.money(item.price!);
    final condition = conditionFromApi(item.condition);
    final status = item.available
        ? null
        : item.reason == UnavailableReason.underReview
            ? l10n.savedItemUnderReview
            : l10n.savedItemNoLongerAvailable;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        if (price != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(price, style: AppTextStyles.cardPrice),
        ],
        if (condition != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(conditionLabel(l10n, condition), style: AppTextStyles.hint),
        ],
        if (status != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(status, style: AppTextStyles.error),
        ],
      ],
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            width: 80,
            height: 80,
            child: AppImage(source: item.thumbnailUrl ?? '', cacheWidth: 240),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: details),
      ],
    );

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // An unavailable item is greyed; the remove action below stays at full strength.
          Opacity(
            opacity: item.available ? 1 : 0.55,
            child: item.available
                ? Semantics(
                    button: true,
                    label: [item.title, if (price != null) price].join(', '),
                    excludeSemantics: true,
                    onTap: onOpen,
                    child: InkWell(onTap: onOpen, child: row),
                  )
                : Semantics(
                    label: [item.title, if (status != null) status].join(', '),
                    excludeSemantics: true,
                    child: row,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // A Wrap, not a Row: at a large text size or in Hindi the two buttons flow onto two lines.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (item.available)
                Tooltip(
                  message: l10n.homeFeatureComingSoon,
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text(l10n.listingViewAddToCart),
                  ),
                ),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.favorite, color: AppColors.brandError),
                label: Text(l10n.savedItemRemove),
                style:
                    TextButton.styleFrom(minimumSize: const Size(0, AppSpacing.xl + AppSpacing.md)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
