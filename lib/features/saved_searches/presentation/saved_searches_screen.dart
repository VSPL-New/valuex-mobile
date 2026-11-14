import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/saved_search.dart';
import 'providers/saved_searches_controller.dart';
import 'saved_search_summary.dart';

/// Saved Searches (US-066): every search the buyer saved, with the daily alert switch and delete
/// (with an undo). Tapping a search opens its results; one whose category or filters no longer
/// exist says so and can only be deleted.
class SavedSearchesScreen extends ConsumerWidget {
  const SavedSearchesScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, SavedSearch search) async {
    final failed = AppLocalizations.of(context).savedSearchAlertsFailed;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(savedSearchesControllerProvider.notifier).toggleAlerts(search.id);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  void _delete(BuildContext context, WidgetRef ref, SavedSearch search) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(savedSearchesControllerProvider.notifier);
    controller.deleteWithUndo(
      search.id,
      onFailed: () => messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.savedSearchDeleteFailed))),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.savedSearchDeleted),
          duration: SavedSearchesController.undoWindow,
          action: SnackBarAction(
            label: l10n.savedSearchUndo,
            onPressed: () => controller.undoDelete(search.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(savedSearchesControllerProvider);
    final searches = async.value;

    final Widget body;
    if (searches == null && async.hasError) {
      body = ErrorView(
        message: l10n.savedSearchesLoadFailed,
        onRetry: () => ref.invalidate(savedSearchesControllerProvider),
      );
    } else if (searches == null) {
      body = const LoadingIndicator();
    } else if (searches.isEmpty) {
      body = const _EmptyState();
    } else {
      body = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedSearchesControllerProvider);
          try {
            await ref.read(savedSearchesControllerProvider.future);
          } on Object {
            // The error is shown in place; the spinner just stops.
          }
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: searches.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final search = searches[index];
            return _SavedSearchCard(
              search: search,
              onOpen: () => context.push(RouteNames.savedSearch(search.id)),
              onToggle: () => _toggle(context, ref, search),
              onDelete: () => _delete(context, ref, search),
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
                      child: Text(l10n.savedSearchesTitle, style: AppTextStyles.heading2),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.bookmark_border_rounded, size: 48, color: AppColors.brandMutedText),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.savedSearchesEmpty,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.savedSearchesEmptyHint,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedSearchCard extends StatelessWidget {
  final SavedSearch search;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SavedSearchCard({
    required this.search,
    required this.onOpen,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = savedSearchSummary(l10n, search.criteria);
    final invalid = !search.valid;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(search.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(summary, style: AppTextStyles.bodySecondary),
        ],
        if (invalid) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            search.invalidMessage ?? l10n.savedSearchInvalid,
            style: AppTextStyles.error,
          ),
        ],
      ],
    );

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          invalid
              ? details
              : Semantics(
                  button: true,
                  label: l10n.savedSearchOpenLabel(search.name),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
                      child: Align(alignment: AlignmentDirectional.centerStart, child: details),
                    ),
                  ),
                ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!invalid)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                        child: Text(l10n.savedSearchAlerts, style: AppTextStyles.bodySecondary)),
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      label: l10n.savedSearchAlertsFor(search.name),
                      child: Switch(value: search.alertsEnabled, onChanged: (_) => onToggle()),
                    ),
                  ],
                ),
              IconButton(
                tooltip: l10n.savedSearchDeleteLabel(search.name),
                constraints: const BoxConstraints(
                  minWidth: AppSizes.minTouchTarget,
                  minHeight: AppSizes.minTouchTarget,
                ),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.brandError),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
