import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/search_criteria.dart';
import '../../domain/saved_search.dart';
import '../providers/saved_searches_controller.dart';

/// "Save search" for the criteria on the Search screen (US-066). Disabled until there is
/// something to save; says so when the search was already saved or the limit is reached.
class SaveSearchButton extends ConsumerWidget {
  final SearchCriteria criteria;

  const SaveSearchButton({super.key, required this.criteria});

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref.read(saveSearchControllerProvider.notifier).save(criteria);
    if (outcome == null) return;
    final message = switch (outcome.status) {
      SaveSearchStatus.saved => l10n.savedSearchSaved,
      SaveSearchStatus.alreadySaved => l10n.savedSearchAlreadySaved,
      SaveSearchStatus.limitReached =>
        outcome.max == null ? l10n.savedSearchLimitUnknown : l10n.savedSearchLimit(outcome.max!),
      SaveSearchStatus.invalid => l10n.savedSearchInvalid,
      SaveSearchStatus.failed => l10n.savedSearchSaveFailed,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saving = ref.watch(saveSearchControllerProvider);
    return TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
      ),
      onPressed: canSaveSearch(criteria) && !saving ? () => _save(context, ref) : null,
      icon: const Icon(Icons.bookmark_add_outlined),
      label: Text(l10n.savedSearchSave),
    );
  }
}
