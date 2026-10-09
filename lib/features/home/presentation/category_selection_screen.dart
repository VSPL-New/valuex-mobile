import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/home_providers.dart';

/// Every category from the backend. Opening a category's listings comes with search (US-011).
class CategorySelectionScreen extends ConsumerWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);

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
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(l10n.homeCategoriesFailed, style: AppTextStyles.error),
                ),
                data: (items) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.brandDivider),
                  itemBuilder: (context, index) {
                    final category = items[index];
                    return ListTile(
                      minTileHeight: AppSizes.minTouchTarget,
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 48,
                        height: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: AppImage(source: category.image ?? '', cacheWidth: 160),
                        ),
                      ),
                      title: Text(category.name, style: AppTextStyles.body),
                      trailing:
                          const Icon(Icons.chevron_right_rounded, color: AppColors.brandMutedText),
                      onTap: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(l10n.homeFeatureComingSoon))),
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
