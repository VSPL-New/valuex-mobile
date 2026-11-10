import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_messages.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/main_nav.dart';
import '../../../home/presentation/widgets/listing_card.dart';
import '../../domain/search_criteria.dart';
import '../providers/search_results_controller.dart';
import '../search_labels.dart';
import 'search_skeleton.dart';

/// The results of one search: skeletons while loading, cards two to a row with more pages on
/// scroll, pull to refresh, and the no-results and error states.
class SearchResultsView extends ConsumerStatefulWidget {
  /// Identifies the search this view shows; see [searchResultsControllerProvider].
  final SearchCriteria initial;

  const SearchResultsView({super.key, required this.initial});

  @override
  ConsumerState<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends ConsumerState<SearchResultsView> {
  /// More is requested when this close to the end of the list.
  static const double _loadMoreDistance = 600;

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
    if (_scroll.position.extentAfter < _loadMoreDistance) {
      ref.read(searchResultsControllerProvider(widget.initial).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = searchResultsControllerProvider(widget.initial);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    const sidePadding = EdgeInsets.symmetric(horizontal: AppSpacing.md);

    Widget box(Widget child) => SliverPadding(
          padding: sidePadding,
          sliver: SliverToBoxAdapter(child: child),
        );

    final List<Widget> slivers;
    if (state.items.isEmpty && state.error != null) {
      slivers = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: searchErrorMessage(l10n, state.error!),
            onRetry: controller.retry,
          ),
        ),
      ];
    } else if (state.items.isEmpty && state.noResults) {
      slivers = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _NoResults(
            filtered: state.criteria.hasFilters,
            onClearFilters: controller.clearFilters,
          ),
        ),
      ];
    } else if (state.items.isEmpty) {
      slivers = [box(const SearchSkeleton())];
    } else {
      final items = state.items;
      slivers = [
        box(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: Text(l10n.searchResultsCount(state.totalItems), style: AppTextStyles.hint),
            ),
          ),
        ),
        SliverPadding(
          padding: sidePadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: (items.length + 1) ~/ 2,
              (context, row) {
                final first = items[row * 2];
                final second = row * 2 + 1 < items.length ? items[row * 2 + 1] : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ListingCard(
                            listing: first.toCardListing(),
                            onTap: () => showComingSoon(context),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md - 4),
                        Expanded(
                          child: second == null
                              ? const SizedBox.shrink()
                              : ListingCard(
                                  listing: second.toCardListing(),
                                  onTap: () => showComingSoon(context),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (state.loadMoreFailed)
          SliverToBoxAdapter(
            child: Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                ),
                onPressed: controller.loadMore,
                child: Text(l10n.searchLoadMoreFailed, textAlign: TextAlign.center),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ];
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final bool filtered;
  final VoidCallback onClearFilters;

  const _NoResults({required this.filtered, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.search_off_rounded, size: 48, color: AppColors.brandMutedText),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                filtered ? l10n.searchNoResultsFilters : l10n.searchNoResults,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
            if (filtered) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                  label: l10n.searchClearFilters, onPressed: onClearFilters, isOutlined: true),
            ],
          ],
        ),
      ),
    );
  }
}
