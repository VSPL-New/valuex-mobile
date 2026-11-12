import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/search_suggestion.dart';
import '../providers/search_suggestions_controller.dart';
import '../suggestion_text.dart';

/// The auto-complete list under the search field. Rows are 48 dp or taller.
class SearchSuggestionsList extends StatelessWidget {
  final SuggestionsState suggestions;
  final ValueChanged<SearchSuggestion> onSelected;

  const SearchSuggestionsList({super.key, required this.suggestions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.searchSuggestionsLabel,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        itemCount: suggestions.items.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions.items[index];
          return SuggestionRow(
            suggestion: suggestion,
            query: suggestions.query,
            onTap: () => onSelected(suggestion),
          );
        },
      ),
    );
  }
}

/// One suggestion: a listing title with the typed part in bold, or a category with its tag.
class SuggestionRow extends StatelessWidget {
  final SearchSuggestion suggestion;
  final String query;
  final VoidCallback onTap;

  const SuggestionRow({
    super.key,
    required this.suggestion,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCategory = suggestion.isCategory;
    final parts = splitTypedPrefix(suggestion.text, query);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: isCategory
          ? l10n.searchSuggestionCategoryLabel(suggestion.text)
          : l10n.searchSuggestionListingLabel(suggestion.text),
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Row(
            children: [
              Icon(
                isCategory ? Icons.category_outlined : Icons.search_rounded,
                color: AppColors.brandMutedText,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      TextSpan(
                        text: parts.typed,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: parts.rest),
                    ],
                  ),
                ),
              ),
              if (isCategory) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.searchSuggestionCategoryTag, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
