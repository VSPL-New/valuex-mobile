import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand_bottom_nav.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/main_nav.dart';
import '../../listing/domain/category.dart';
import '../../listing/presentation/providers/category_providers.dart';
import '../domain/search_criteria.dart';
import 'providers/search_results_controller.dart';
import 'search_labels.dart';
import 'search_routes.dart';
import 'widgets/category_node_tile.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/intent_sheet.dart';
import 'widgets/search_results_view.dart';

/// Search: the text field, the filters and the results. With nothing asked yet it offers the
/// popular categories. [initial] is the text or category the screen opens with.
class SearchScreen extends ConsumerStatefulWidget {
  final SearchCriteria initial;

  const SearchScreen({super.key, this.initial = const SearchCriteria()});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _text;
  bool _choosingIntent = false;

  SearchResultsController get _controller =>
      ref.read(searchResultsControllerProvider(widget.initial).notifier);

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initial.query);
    // A Real Estate category asks for Buy, Rent or Lease before any search call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(searchResultsControllerProvider(widget.initial)).needsIntent) {
        _askIntent();
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _askIntent() async {
    if (_choosingIntent) return;
    _choosingIntent = true;
    final intent = await showIntentSheet(context);
    _choosingIntent = false;
    if (intent != null && mounted) await _controller.chooseIntent(intent);
  }

  Future<void> _openFilters(SearchState state) async {
    final result = await showFilterSheet(
      context,
      criteria: state.criteria,
      facets: state.facets,
    );
    if (result != null && mounted) await _controller.applyCriteria(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = searchResultsControllerProvider(widget.initial);
    final state = ref.watch(provider);
    final criteria = state.criteria;
    ref.listen(provider.select((s) => s.needsIntent), (previous, needed) {
      if (needed && !(previous ?? false)) _askIntent();
    });

    return Scaffold(
      bottomNavigationBar: BrandBottomNav(
        current: BottomNavItem.search,
        chatsHasUnread: true,
        onSelected: (item) =>
            onMainNavSelected(context, ref, current: BottomNavItem.search, item: item),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  if (context.canPop())
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: SquareBackButton(onPressed: context.pop),
                    ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        criteria.categoryName ?? l10n.searchTitle,
                        style: AppTextStyles.heading2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(l10n)),
                  _FilterButton(count: criteria.filterCount, onPressed: () => _openFilters(state)),
                ],
              ),
            ),
            if (criteria.realEstate && criteria.intent != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                  ),
                  onPressed: _askIntent,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(l10n.searchIntentChange(intentLabel(l10n, criteria.intent!))),
                ),
              ),
            Expanded(child: _body(l10n, state)),
          ],
        ),
      ),
    );
  }

  Widget _field(AppLocalizations l10n) {
    return Semantics(
      label: l10n.searchFieldLabel,
      textField: true,
      child: TextField(
        controller: _text,
        maxLength: SearchCriteria.maxQueryLength,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.input,
        onChanged: _controller.setQuery,
        onSubmitted: (_) => _controller.submit(),
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text(
          l10n.searchQueryCounter(currentLength, maxLength ?? SearchCriteria.maxQueryLength),
          style: AppTextStyles.hint,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchFieldHint,
          prefixIcon: const ExcludeSemantics(child: Icon(Icons.search_rounded)),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (context, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.searchClearText,
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.minTouchTarget,
                      minHeight: AppSizes.minTouchTarget,
                    ),
                    onPressed: () {
                      _text.clear();
                      _controller.setQuery('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, SearchState state) {
    if (state.criteria.isBlank) return const _StartView();
    if (state.needsIntent) return _IntentPrompt(onChoose: _askIntent);
    return SearchResultsView(initial: widget.initial);
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _FilterButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: count > 0 ? l10n.searchFiltersApplied(count) : l10n.searchFilters,
      constraints: const BoxConstraints(
        minWidth: AppSizes.minTouchTarget,
        minHeight: AppSizes.minTouchTarget,
      ),
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.tune_rounded),
      ),
    );
  }
}

/// Shown until the buyer chooses Buy, Rent or Lease for a Real Estate category.
class _IntentPrompt extends StatelessWidget {
  final VoidCallback onChoose;

  const _IntentPrompt({required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.searchIntentPrompt, style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: l10n.searchIntentChoose, onPressed: onChoose),
          ],
        ),
      ),
    );
  }
}

/// Nothing asked yet: the popular categories and a way into the full list.
class _StartView extends ConsumerWidget {
  const _StartView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const query = (parentCode: null, scope: CategoryScope.popular);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Text(l10n.searchStartHint, style: AppTextStyles.hint),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(l10n.searchPopularCategories, style: AppTextStyles.sectionTitle),
        ),
        ref.watch(categoryChildrenProvider(query)).when(
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                message: l10n.searchCategoriesFailed,
                onRetry: () => ref.invalidate(categoryChildrenProvider(query)),
              ),
              data: (nodes) => Column(
                children: [
                  for (final node in nodes)
                    CategoryNodeTile(node: node, onTap: () => openCategory(context, node)),
                ],
              ),
            ),
        ListTile(
          minTileHeight: AppSizes.minTouchTarget,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.grid_view_rounded, color: AppColors.brandLink),
          title: Text(l10n.searchBrowseAll, style: AppTextStyles.link),
          onTap: () => context.push(RouteNames.searchCategories),
        ),
      ],
    );
  }
}
