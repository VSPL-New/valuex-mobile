import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/category.dart';
import 'listing_error_messages.dart';
import 'providers/category_providers.dart';

/// Opens the category picker and returns the code of the chosen leaf (L3) category, or null when
/// the seller goes back without choosing.
Future<String?> pickCategory(BuildContext context, {String? selectedCode}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => CategoryPickerScreen(selectedCode: selectedCode)),
  );
}

/// US-006: browse the category tree (popular first, then the rest, down to a leaf) or search by
/// name. Only a leaf category can be chosen.
class CategoryPickerScreen extends ConsumerStatefulWidget {
  /// How long to wait after typing before searching.
  static const Duration searchDelay = Duration(milliseconds: 300);
  static const int minSearchLength = 2;

  final String? selectedCode;

  const CategoryPickerScreen({super.key, this.selectedCode});

  @override
  ConsumerState<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends ConsumerState<CategoryPickerScreen> {
  final List<CategoryNode> _trail = [];
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _showOthers = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(CategoryPickerScreen.searchDelay, () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  void _open(CategoryNode node) {
    if (node.hasChildren && node.level < 3) {
      setState(() {
        _trail.add(node);
        _showOthers = false;
      });
    } else {
      Navigator.of(context).pop(node.code);
    }
  }

  void _back() {
    if (_trail.isEmpty) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _trail.removeLast();
        _showOthers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searching = _query.isNotEmpty;
    return PopScope(
      canPop: _trail.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    SquareBackButton(onPressed: _back),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          _trail.isEmpty ? l10n.itemCategoryPickerTitle : _trail.last.name,
                          style: AppTextStyles.heading2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppTextField(
                  controller: _search,
                  hint: l10n.itemCategorySearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  onChanged: _onSearchChanged,
                ),
              ),
              Expanded(
                child: searching
                    ? _SearchResults(
                        query: _query, selectedCode: widget.selectedCode, onPick: _pickFromSearch)
                    : _Browse(
                        parent: _trail.isEmpty ? null : _trail.last,
                        selectedCode: widget.selectedCode,
                        showOthers: _showOthers,
                        onShowOthers: () => setState(() => _showOthers = true),
                        onOpen: _open,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickFromSearch(CategoryRef category) => Navigator.of(context).pop(category.code);
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final String? selectedCode;
  final ValueChanged<CategoryRef> onPick;

  const _SearchResults({required this.query, required this.selectedCode, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (query.length < CategoryPickerScreen.minSearchLength) {
      return _Message(text: l10n.itemCategorySearchMin);
    }
    return ref.watch(categorySearchProvider(query)).when(
          loading: () => const LoadingIndicator(),
          error: (error, stack) => ErrorView(
            message: listingErrorMessage(l10n, error),
            onRetry: () => ref.invalidate(categorySearchProvider(query)),
          ),
          data: (hits) => hits.isEmpty
              ? _Message(text: l10n.itemCategoryNoResults)
              : ListView(
                  children: [
                    for (final hit in hits)
                      ListTile(
                        title: Text(hit.name),
                        subtitle: Text(hit.parentsLabel, style: AppTextStyles.hint),
                        selected: hit.code == selectedCode,
                        onTap: () => onPick(hit),
                      ),
                  ],
                ),
        );
  }
}

/// The children of [parent] (the top level when null): popular ones first and the rest on
/// request, except for leaves, which are listed in full.
class _Browse extends ConsumerWidget {
  final CategoryNode? parent;
  final String? selectedCode;
  final bool showOthers;
  final VoidCallback onShowOthers;
  final ValueChanged<CategoryNode> onOpen;

  const _Browse({
    required this.parent,
    required this.selectedCode,
    required this.showOthers,
    required this.onShowOthers,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final leaves = parent?.level == 2;
    final first =
        (parentCode: parent?.code, scope: leaves ? CategoryScope.all : CategoryScope.popular);
    final others = (parentCode: parent?.code, scope: CategoryScope.others);

    return ref.watch(categoryChildrenProvider(first)).when(
          loading: () => const LoadingIndicator(),
          error: (error, stack) => ErrorView(
            message: listingErrorMessage(l10n, error),
            onRetry: () => ref.invalidate(categoryChildrenProvider(first)),
          ),
          data: (nodes) => ListView(
            children: [
              if (!leaves && nodes.isNotEmpty) _Heading(text: l10n.itemCategoryPopular),
              for (final node in nodes)
                _NodeTile(node: node, selectedCode: selectedCode, onOpen: onOpen),
              if (!leaves && !showOthers)
                TextButton(onPressed: onShowOthers, child: Text(l10n.itemCategoryMore)),
              if (!leaves && showOthers) ...[
                _Heading(text: l10n.itemCategoryAll),
                ref.watch(categoryChildrenProvider(others)).when(
                      loading: () => const LoadingIndicator(),
                      error: (error, stack) => ErrorView(
                        message: listingErrorMessage(l10n, error),
                        onRetry: () => ref.invalidate(categoryChildrenProvider(others)),
                      ),
                      data: (rest) => Column(children: [
                        for (final node in rest)
                          _NodeTile(node: node, selectedCode: selectedCode, onOpen: onOpen),
                      ]),
                    ),
              ],
            ],
          ),
        );
  }
}

class _NodeTile extends StatelessWidget {
  final CategoryNode node;
  final String? selectedCode;
  final ValueChanged<CategoryNode> onOpen;

  const _NodeTile({required this.node, required this.selectedCode, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(node.name),
      selected: node.code == selectedCode,
      trailing: node.hasChildren && node.level < 3
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.brandForeground)
          : null,
      onTap: () => onOpen(node),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: AppTextStyles.label),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(text, style: AppTextStyles.body, textAlign: TextAlign.center),
      ),
    );
  }
}
