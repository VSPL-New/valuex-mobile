import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../search/presentation/search_routes.dart';
import '../../listing/domain/category.dart';
import '../../listing/presentation/providers/category_providers.dart';

/// Every backend root category; selecting one opens the shared Search browser expanded.
class CategorySelectionScreen extends ConsumerWidget {
  const CategorySelectionScreen({super.key});

  static const CategoryQuery _categoryQuery = (parentCode: null, scope: CategoryScope.all);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoryChildrenProvider(_categoryQuery));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: SquareBackButton(
                onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Semantics(
                header: true,
                child: Text(l10n.categoriesTitle, style: AppTextStyles.heading2),
              ),
            ),
            Expanded(
              child: categories.when(
                loading: () => const LoadingIndicator(),
                error: (error, stack) => ErrorView(
                  message: l10n.homeCategoriesFailed,
                  onRetry: () => ref.invalidate(categoryChildrenProvider(_categoryQuery)),
                ),
                data: (items) => items.isEmpty
                    ? Center(child: Text(l10n.searchCategoriesEmpty, style: AppTextStyles.hint))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: AppColors.brandDivider),
                        itemBuilder: (context, index) {
                          final category = items[index];
                          return ListTile(
                            minTileHeight: AppSizes.minTouchTarget,
                            contentPadding: EdgeInsets.zero,
                            leading: CategoryIcon(name: category.name, code: category.code),
                            title: Text(category.name, style: AppTextStyles.body),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: AppColors.brandMutedText),
                            onTap: () => openCategory(context, category),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
