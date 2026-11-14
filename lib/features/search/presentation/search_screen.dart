import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand_bottom_nav.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/main_nav.dart';
import '../../auth/presentation/providers/session_controller.dart';
import '../../auth/presentation/providers/session_state.dart';
import '../../listing/domain/category.dart';
import '../../saved_searches/presentation/widgets/save_search_button.dart';
import '../domain/search_criteria.dart';
import '../domain/search_suggestion.dart';
import '../../voice_search/presentation/widgets/voice_listening_sheet.dart';
import '../../voice_search/presentation/widgets/voice_search_button.dart';
import 'providers/search_results_controller.dart';
import 'providers/search_suggestions_controller.dart';
import 'search_labels.dart';
import 'search_routes.dart';
import 'widgets/category_browser.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/intent_sheet.dart';
import 'widgets/search_results_view.dart';
import 'widgets/search_suggestions_list.dart';

/// Search: the text field, the filters and the results. With nothing asked yet it offers the
/// popular categories. [initial] is the text or category the screen opens with.
class SearchScreen extends ConsumerStatefulWidget {
  final SearchCriteria initial;
  final CategoryNode? browseParent;
  final bool browseRealEstate;

  const SearchScreen({
    super.key,
    this.initial = const SearchCriteria(),
    this.browseParent,
    this.browseRealEstate = false,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const int _suggestedCategoryLevel = 3;

  late final TextEditingController _text;
  final FocusNode _focus = FocusNode();
  bool _choosingIntent = false;
  bool _hasBrowsed = false;

  SearchResultsController get _controller =>
      ref.read(searchResultsControllerProvider(widget.initial).notifier);

  SearchSuggestionsController get _suggestions =>
      ref.read(searchSuggestionsControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initial.query);
    _focus.addListener(() {
      if (ref.read(sessionControllerProvider).value is Authenticated) {
        _suggestions.onFocusChanged(_focus.hasFocus);
      }
    });
    // A Real Estate category asks for Buy, Rent or Lease before any search call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(searchResultsControllerProvider(widget.initial)).needsIntent) {
        _askIntent();
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _controller.setQuery(text);
    _suggestions.onTextChanged(text);
  }

  void _onSubmitted() {
    _suggestions.onSubmitted();
    _controller.submit();
  }

  /// A listing title searches for that text. A category suggestion is always an enabled L3 leaf,
  /// so its results open as an L3 category and the facet filters load. If it lies under Real
  /// Estate the server answers `ERROR_INTENT_REQUIRED` and the intent chooser follows.
  void _selectSuggestion(SearchSuggestion suggestion) {
    _suggestions.onSubmitted();
    _focus.unfocus();
    final code = suggestion.categoryCode;
    if (suggestion.isCategory && code != null) {
      context.push(
        searchLocation(
          categoryCode: code,
          categoryName: suggestion.text,
          categoryLevel: _suggestedCategoryLevel,
        ),
      );
      return;
    }
    _text.value = TextEditingValue(
      text: suggestion.text,
      selection: TextSelection.collapsed(offset: suggestion.text.length),
    );
    final criteria = ref.read(searchResultsControllerProvider(widget.initial)).criteria;
    _controller.applyCriteria(criteria.copyWith(query: suggestion.text));
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

  Future<void> _startVoiceSearch() async {
    final result = await showVoiceListeningSheet(context);
    if (!mounted) return;
    if (result == null) return;
    if (result == voiceTypeInsteadResult) {
      _focus.requestFocus();
      return;
    }
    _suggestions.onSubmitted();
    _focus.unfocus();
    _text.value = TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
    await _controller.applyVoiceQuery(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = searchResultsControllerProvider(widget.initial);
    final state = ref.watch(provider);
    final criteria = state.criteria;
    final signedIn = ref.watch(sessionControllerProvider).value is Authenticated;
    final suggestions =
        signedIn ? ref.watch(searchSuggestionsControllerProvider) : const SuggestionsState();
    if (criteria.isBlank) _hasBrowsed = true;
    final browsing = criteria.isBlank && suggestions.isEmpty;
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
                  Expanded(child: _field(l10n, signedIn: signedIn)),
                  if (!criteria.isBlank)
                    _FilterButton(
                      count: criteria.filterCount,
                      onPressed: () => _openFilters(state),
                    ),
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
            if (signedIn && !browsing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SaveSearchButton(criteria: criteria),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                      ),
                      onPressed: () => context.push(RouteNames.savedSearches),
                      child: Text(l10n.savedSearchesTitle),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_hasBrowsed)
                    Visibility(
                      visible: browsing,
                      maintainState: true,
                      child: CategoryBrowser(
                        initialParent: widget.browseParent,
                        realEstate: widget.browseRealEstate,
                      ),
                    ),
                  if (!browsing)
                    suggestions.isEmpty
                        ? _body(state)
                        // Keep suggestion taps inside the field's focus region.
                        : TextFieldTapRegion(
                            child: SearchSuggestionsList(
                              suggestions: suggestions,
                              onSelected: _selectSuggestion,
                            ),
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(AppLocalizations l10n, {required bool signedIn}) {
    return Semantics(
      label: l10n.searchFieldLabel,
      textField: true,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        maxLength: SearchCriteria.maxQueryLength,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.input,
        readOnly: !signedIn,
        onTap: signedIn ? null : () => context.push(RouteNames.search),
        onChanged: signedIn ? _onChanged : null,
        onSubmitted: signedIn ? (_) => _onSubmitted() : null,
        // The limit is enforced silently; no counter is shown.
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        decoration: InputDecoration(
          hintText: l10n.searchFieldHint,
          prefixIcon: const ExcludeSemantics(child: Icon(Icons.search_rounded)),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (context, value, child) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value.text.isNotEmpty)
                  IconButton(
                    tooltip: l10n.searchClearText,
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.minTouchTarget,
                      minHeight: AppSizes.minTouchTarget,
                    ),
                    onPressed: () {
                      _text.clear();
                      _onChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                VoiceSearchButton(onPressed: _startVoiceSearch),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(SearchState state) {
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
