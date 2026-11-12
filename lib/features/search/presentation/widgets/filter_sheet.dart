import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/state_picker_field.dart';
import '../../../listing/domain/listing_details.dart' as details;
import '../../domain/search_criteria.dart';
import '../../domain/search_facet.dart';
import '../../domain/search_sort.dart';
import '../search_labels.dart';
import 'toggle_chip.dart';

/// Opens the filters for [criteria]; [facets] are the category filters from the last response.
/// Returns the new criteria when the user applies them, null when the sheet is closed.
Future<SearchCriteria?> showFilterSheet(
  BuildContext context, {
  required SearchCriteria criteria,
  required List<SearchFacet> facets,
}) {
  return showModalBottomSheet<SearchCriteria>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => FilterSheet(criteria: criteria, facets: facets),
  );
}

/// Price range (a minimum above the maximum is shown inline), condition, place, sort and the
/// filters of the L3 category. The choices are a draft until Apply.
class FilterSheet extends StatefulWidget {
  final SearchCriteria criteria;
  final List<SearchFacet> facets;

  const FilterSheet({super.key, required this.criteria, required this.facets});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  static final _decimal = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));
  static final _number = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

  late final TextEditingController _priceMin;
  late final TextEditingController _priceMax;
  late final TextEditingController _city;
  final Map<String, TextEditingController> _rangeMin = {};
  final Map<String, TextEditingController> _rangeMax = {};
  late Set<String> _conditions;
  late Map<String, String> _facets;
  late SearchSort _sort;
  String? _state;

  @override
  void initState() {
    super.initState();
    final criteria = widget.criteria;
    _priceMin = TextEditingController(text: _text(criteria.priceMin));
    _priceMax = TextEditingController(text: _text(criteria.priceMax));
    _city = TextEditingController(text: criteria.city ?? '');
    _conditions = {...criteria.conditions};
    _facets = {...criteria.facets};
    _sort = criteria.sort;
    _state = criteria.state;
    for (final facet in widget.facets.where((f) => f.type == FacetType.number)) {
      final parts = (criteria.facets[facet.key] ?? '').split('..');
      _rangeMin[facet.key] = TextEditingController(text: parts.first);
      _rangeMax[facet.key] = TextEditingController(text: parts.length > 1 ? parts.last : '');
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _priceMin,
      _priceMax,
      _city,
      ..._rangeMin.values,
      ..._rangeMax.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _text(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  static double? _parse(String text) => double.tryParse(text.trim());

  static bool _inverted(String min, String max) {
    final low = _parse(min);
    final high = _parse(max);
    return low != null && high != null && low > high;
  }

  bool get _priceInverted => _inverted(_priceMin.text, _priceMax.text);

  bool _rangeInverted(String key) => _inverted(_rangeMin[key]!.text, _rangeMax[key]!.text);

  bool get _valid => !_priceInverted && !_rangeMin.keys.any(_rangeInverted);

  void _reset() {
    setState(() {
      _priceMin.clear();
      _priceMax.clear();
      _city.clear();
      for (final controller in [..._rangeMin.values, ..._rangeMax.values]) {
        controller.clear();
      }
      _conditions = {};
      _facets = {};
      _state = null;
      _sort = SearchSort.relevance;
    });
  }

  SearchCriteria _result() {
    final facets = {..._facets};
    for (final key in _rangeMin.keys) {
      final low = _rangeMin[key]!.text.trim();
      final high = _rangeMax[key]!.text.trim();
      if (low.isEmpty && high.isEmpty) {
        facets.remove(key);
      } else {
        facets[key] = '$low..$high';
      }
    }
    final city = _city.text.trim();
    return widget.criteria.copyWith(
      priceMin: _parse(_priceMin.text),
      priceMax: _parse(_priceMax.text),
      conditions: widget.criteria.allowsConditions ? _conditions : const {},
      state: _state,
      city: city.isEmpty ? null : city,
      facets: facets,
      sort: _sort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final criteria = widget.criteria;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(l10n.filterTitle, style: AppTextStyles.heading2),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                  ),
                  onPressed: _reset,
                  child: Text(l10n.filterReset),
                ),
                IconButton(
                  tooltip: l10n.filterClose,
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.minTouchTarget,
                    minHeight: AppSizes.minTouchTarget,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: l10n.filterSortTitle,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final sort in SearchSort.values)
                          ToggleChip(
                            label: sortLabel(l10n, sort),
                            selected: _sort == sort,
                            onTap: () => setState(() => _sort = sort),
                          ),
                      ],
                    ),
                  ),
                  _Section(
                    title: l10n.filterPriceTitle,
                    child: _RangeFields(
                      minController: _priceMin,
                      maxController: _priceMax,
                      minLabel: l10n.filterPriceMin,
                      maxLabel: l10n.filterPriceMax,
                      formatter: _decimal,
                      error: _priceInverted ? l10n.searchErrorPriceRange : null,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  if (criteria.allowsConditions)
                    _Section(
                      title: l10n.filterConditionTitle,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final condition in details.ListingCondition.values)
                            ToggleChip(
                              label: searchConditionLabel(l10n, condition),
                              selected: _conditions.contains(condition.apiValue),
                              onTap: () => setState(() {
                                if (!_conditions.remove(condition.apiValue)) {
                                  _conditions.add(condition.apiValue);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  _Section(
                    title: l10n.filterLocationTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatePickerField(
                                value: _state,
                                onChanged: (value) => setState(() => _state = value),
                              ),
                            ),
                            if (_state != null)
                              IconButton(
                                tooltip: l10n.filterClearState,
                                constraints: const BoxConstraints(
                                  minWidth: AppSizes.minTouchTarget,
                                  minHeight: AppSizes.minTouchTarget,
                                ),
                                onPressed: () => setState(() => _state = null),
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(controller: _city, label: l10n.filterCity),
                      ],
                    ),
                  ),
                  for (final facet in widget.facets) _facetSection(l10n, facet),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: AppButton(
              label: l10n.filterApply,
              onPressed: _valid ? () => Navigator.of(context).pop(_result()) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _facetSection(AppLocalizations l10n, SearchFacet facet) {
    switch (facet.type) {
      case FacetType.option:
        if (facet.buckets.isEmpty) return const SizedBox.shrink();
        return _Section(
          title: facet.label,
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final bucket in facet.buckets)
                ToggleChip(
                  label: l10n.filterBucketLabel(bucket.label, bucket.count),
                  selected: _facets[facet.key] == bucket.code,
                  onTap: () => setState(() {
                    if (_facets[facet.key] == bucket.code) {
                      _facets.remove(facet.key);
                    } else {
                      _facets[facet.key] = bucket.code;
                    }
                  }),
                ),
            ],
          ),
        );
      case FacetType.number:
        final low = facet.min;
        final high = facet.max;
        return _Section(
          title: facet.label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (low != null && high != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    l10n.filterRangeAvailable(_text(low), _text(high)),
                    style: AppTextStyles.hint,
                  ),
                ),
              _RangeFields(
                minController: _rangeMin[facet.key]!,
                maxController: _rangeMax[facet.key]!,
                minLabel: l10n.filterRangeMin(facet.label),
                maxLabel: l10n.filterRangeMax(facet.label),
                formatter: _number,
                error: _rangeInverted(facet.key) ? l10n.filterRangeError : null,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        );
      case FacetType.boolean:
        return _Section(
          title: null,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(facet.label, style: AppTextStyles.body),
            value: _facets[facet.key] == 'true',
            onChanged: (on) => setState(() {
              if (on) {
                _facets[facet.key] = 'true';
              } else {
                _facets.remove(facet.key);
              }
            }),
          ),
        );
    }
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Semantics(header: true, child: Text(title, style: AppTextStyles.sectionTitle)),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}

/// Two number fields side by side, with the error under them.
class _RangeFields extends StatelessWidget {
  final TextEditingController minController;
  final TextEditingController maxController;
  final String minLabel;
  final String maxLabel;
  final TextInputFormatter formatter;
  final String? error;
  final VoidCallback onChanged;

  const _RangeFields({
    required this.minController,
    required this.maxController,
    required this.minLabel,
    required this.maxLabel,
    required this.formatter,
    required this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    Widget field(TextEditingController controller, String label) => Expanded(
          child: AppTextField(
            controller: controller,
            label: label,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [formatter],
            onChanged: (_) => onChanged(),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            field(minController, minLabel),
            const SizedBox(width: AppSpacing.sm),
            field(maxController, maxLabel),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          FieldError(text: error),
        ],
      ],
    );
  }
}
