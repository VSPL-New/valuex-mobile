import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/category_icon.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../listing/domain/category.dart';
import '../../../listing/presentation/providers/category_providers.dart';
import '../search_routes.dart';
import 'category_browser_tiles.dart';

/// Expansion is local UI state; taxonomy data stays in the shared providers.
class CategoryBrowser extends ConsumerStatefulWidget {
  final CategoryNode? initialParent;
  final bool realEstate;

  const CategoryBrowser({super.key, this.initialParent, this.realEstate = false});

  @override
  ConsumerState<CategoryBrowser> createState() => _CategoryBrowserState();
}

class _CategoryBrowserState extends ConsumerState<CategoryBrowser> {
  final _scroll = ScrollController();
  bool _showMoreCategories = false;
  CategoryNode? _parent;
  String? _expandedL1;
  String? _expandedL2;

  @override
  void initState() {
    super.initState();
    _parent = widget.initialParent;
    if (_parent?.level == 1) _expandedL1 = _parent!.code;
    if (_parent?.level == 2) _expandedL2 = _parent!.code;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parent = _parent;
    return SingleChildScrollView(
      key: const PageStorageKey('search-category-browser'),
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.searchStartHint, style: AppTextStyles.hint),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.searchCategoriesTitle, style: AppTextStyles.sectionTitle),
              ),
              _action(
                l10n.searchBrowseAll,
                () => setState(() {
                  _parent = null;
                  _expandedL1 = null;
                  _expandedL2 = null;
                  _showMoreCategories = true;
                  _scroll.jumpTo(0);
                }),
              ),
            ],
          ),
          if (parent != null)
            _card(parent, realEstate: widget.realEstate || isRealEstateRoot(parent))
          else ...[
            Text(l10n.searchPopularCategories, style: AppTextStyles.hint),
            const SizedBox(height: AppSpacing.sm),
            _load(
                null,
                CategoryScope.popular,
                (nodes) => Column(
                      children: [
                        for (final node in nodes) _card(node, realEstate: isRealEstateRoot(node)),
                      ],
                    )),
            _action(
              l10n.searchMoreCategories,
              () => setState(() => _showMoreCategories = !_showMoreCategories),
              expanded: _showMoreCategories,
            ),
            if (_showMoreCategories)
              _load(
                  null,
                  CategoryScope.others,
                  (nodes) => Column(
                        children: [
                          for (final node in nodes) _card(node, realEstate: isRealEstateRoot(node)),
                        ],
                      )),
          ],
        ],
      ),
    );
  }

  Widget _card(CategoryNode node, {required bool realEstate}) {
    final expanded = node.level == 1 ? _expandedL1 == node.code : _expandedL2 == node.code;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.brandSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: expanded ? AppColors.brandPrimary : AppColors.brandDivider),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _branch(node, realEstate: realEstate),
        ),
      ),
    );
  }

  Widget _branch(CategoryNode node, {required bool realEstate}) {
    final l10n = AppLocalizations.of(context);
    final expanded = node.level == 1 ? _expandedL1 == node.code : _expandedL2 == node.code;
    final canExpand = node.hasChildren && node.level < 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryBranchHeading(
          node: node,
          expanded: canExpand ? expanded : null,
          onViewAll: canExpand && expanded && node.level == 2
              ? () => openCategoryListings(context, node, realEstate: realEstate)
              : null,
          onTap: () {
            if (!canExpand) {
              openCategoryListings(context, node, realEstate: realEstate);
              return;
            }
            setState(() {
              if (node.level == 1) {
                _expandedL1 = expanded ? null : node.code;
                _expandedL2 = null;
              } else {
                _expandedL2 = expanded ? null : node.code;
              }
            });
          },
        ),
        if (canExpand && expanded) ...[
          if (node.level == 1)
            Align(
              alignment: Alignment.centerLeft,
              child: _action(
                l10n.searchViewAllIn(node.name),
                () => openCategoryListings(context, node, realEstate: realEstate),
              ),
            ),
          const Divider(color: AppColors.brandDivider),
          if (node.level == 1)
            _load(
                node.code,
                CategoryScope.all,
                (nodes) => Column(
                      children: [
                        for (final child in [
                          ...nodes.where((child) => child.popular),
                          ...nodes.where((child) => !child.popular),
                        ])
                          _branch(child, realEstate: realEstate),
                      ],
                    ))
          else
            _load(
                node.code,
                CategoryScope.all,
                (nodes) => CategoryLeafGrid(
                      nodes: nodes,
                      fallbackIcon: categoryIconFor(name: node.name, code: node.code),
                      onSelected: (leaf) =>
                          openCategoryListings(context, leaf, realEstate: realEstate),
                    )),
        ],
      ],
    );
  }

  Widget _load(
    String? parent,
    CategoryScope scope,
    Widget Function(List<CategoryNode>) builder,
  ) {
    final query = (parentCode: parent, scope: scope);
    final l10n = AppLocalizations.of(context);
    return ref.watch(categoryChildrenProvider(query)).when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LoadingIndicator(),
          ),
          error: (error, stack) => ErrorView(
            message: l10n.searchCategoriesFailed,
            onRetry: () => ref.invalidate(categoryChildrenProvider(query)),
          ),
          data: (nodes) => nodes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(l10n.searchCategoriesEmpty, style: AppTextStyles.hint),
                )
              : builder(nodes),
        );
  }

  Widget _action(String label, VoidCallback onPressed, {bool? expanded}) {
    return Semantics(
      expanded: expanded,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandLink,
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label)),
            if (expanded != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            ],
          ],
        ),
      ),
    );
  }
}
