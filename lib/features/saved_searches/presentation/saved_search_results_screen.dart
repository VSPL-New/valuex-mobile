import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../search/presentation/search_screen.dart';
import 'providers/saved_searches_controller.dart';

/// Opens the results of one saved search (`/search/saved?id=`): what a tap on a saved search and
/// the daily alert lead to. The search is found in the account's list, so a deleted one or one
/// whose criteria are no longer valid shows a message instead of results.
class SavedSearchResultsScreen extends ConsumerWidget {
  final String savedSearchId;

  const SavedSearchResultsScreen({super.key, required this.savedSearchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(savedSearchesControllerProvider);
    final searches = async.value;

    if (searches == null && async.hasError) {
      return _Frame(
        child: ErrorView(
          message: l10n.savedSearchesLoadFailed,
          onRetry: () => ref.invalidate(savedSearchesControllerProvider),
        ),
      );
    }
    if (searches == null) return const _Frame(child: LoadingIndicator());

    final search = searches.where((s) => s.id == savedSearchId).firstOrNull;
    if (search == null || !search.valid) {
      return _Frame(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  search == null ? l10n.savedSearchNotFound : l10n.savedSearchInvalid,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l10n.savedSearchViewAll,
                  isOutlined: true,
                  onPressed: () => context.go(RouteNames.savedSearches),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SearchScreen(initial: search.criteria);
  }
}

class _Frame extends StatelessWidget {
  final Widget child;

  const _Frame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  SquareBackButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
