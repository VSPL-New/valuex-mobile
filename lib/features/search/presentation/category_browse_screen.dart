import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../listing/domain/category.dart';
import '../../listing/presentation/providers/category_providers.dart';
import 'search_routes.dart';
import 'widgets/category_node_tile.dart';

/// Browse the taxonomy level by level: L1, then L2, then L3. Each list shows the popular
/// categories first and the others after them; a parent can be opened as a whole.
class CategoryBrowseScreen extends ConsumerWidget {
  final String? parentCode;
  final String? parentName;
  final int? parentLevel;

  /// The user came through Real Estate, so its listings ask for Buy, Rent or Lease.
  final bool realEstate;

  const CategoryBrowseScreen({
    super.key,
    this.parentCode,
    this.parentName,
    this.parentLevel,
    this.realEstate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = parentName;
    // The children of an L2 category are leaves: one plain list, popular ones are not split out.
    final leaves = parentLevel == 2;
    final first = (
      parentCode: parentCode,
      scope: leaves ? CategoryScope.all : CategoryScope.popular,
    );
    final others = (parentCode: parentCode, scope: CategoryScope.others);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: SquareBackButton(
                onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.search),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Semantics(
                header: true,
                child: Text(name ?? l10n.searchCategoriesTitle, style: AppTextStyles.heading2),
              ),
            ),
            Expanded(
              child: ref.watch(categoryChildrenProvider(first)).when(
                    loading: () => const LoadingIndicator(),
                    error: (error, stack) => ErrorView(
                      message: l10n.searchCategoriesFailed,
                      onRetry: () => ref.invalidate(categoryChildrenProvider(first)),
                    ),
                    data: (nodes) => ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        if (parentCode != null)
                          ListTile(
                            minTileHeight: AppSizes.minTouchTarget,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.search_rounded, color: AppColors.brandLink),
                            title: Text(
                              l10n.searchViewAllIn(name ?? ''),
                              style: AppTextStyles.link,
                            ),
                            onTap: () => context.push(
                              searchLocation(
                                categoryCode: parentCode,
                                categoryName: name,
                                categoryLevel: parentLevel,
                                realEstate: realEstate,
                              ),
                            ),
                          ),
                        if (!leaves && nodes.isNotEmpty)
                          _Heading(text: l10n.searchCategoriesPopular),
                        for (final node in nodes) _tile(context, node),
                        if (!leaves) ..._othersSection(context, ref, l10n, others),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, CategoryNode node) => CategoryNodeTile(
        node: node,
        onTap: () => openCategory(context, node, realEstate: realEstate),
      );

  List<Widget> _othersSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    CategoryQuery others,
  ) {
    return ref.watch(categoryChildrenProvider(others)).when(
          loading: () => const [LoadingIndicator()],
          error: (error, stack) => [
            ErrorView(
              message: l10n.searchCategoriesFailed,
              onRetry: () => ref.invalidate(categoryChildrenProvider(others)),
            ),
          ],
          data: (rest) => [
            if (rest.isNotEmpty) _Heading(text: l10n.searchCategoriesOthers),
            for (final node in rest) _tile(context, node),
          ],
        );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTextStyles.sectionTitle),
      ),
    );
  }
}
