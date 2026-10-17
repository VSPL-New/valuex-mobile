import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/field_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../../home/presentation/widgets/location_prompt.dart';
import '../../home/presentation/widgets/location_sheet.dart';
import '../../home/presentation/widgets/saved_location_dialog.dart';
import '../domain/listing_details.dart';
import 'listing_error_messages.dart';
import 'providers/item_details_controller.dart';
import 'widgets/category_chips.dart';
import 'widgets/option_chip.dart';
import 'widgets/sell_step_header.dart';

/// Sell step 2 of 4 (Figma Make: CreateListingScreen, "details" step, with the price block of the
/// "price" step merged in): title, category, condition, description, location and price. Empty
/// when AI is off; prefilled and editable when AI filled it (US-114).
class ItemDetailsScreen extends ConsumerStatefulWidget {
  final ItemDetailsArgs args;

  const ItemDetailsScreen({super.key, required this.args});

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;

  ItemDetailsController get _controller =>
      ref.read(itemDetailsControllerProvider(widget.args).notifier);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(itemDetailsControllerProvider(widget.args)).draft;
    _title = TextEditingController(text: draft.title);
    _description = TextEditingController(text: draft.description);
    _price = TextEditingController(text: draft.price);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final result = await _controller.save();
    if (!mounted) return;
    if (result.saved) {
      unawaited(context.push(RouteNames.sellPlan));
      return;
    }
    final error = result.error;
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(listingErrorMessage(AppLocalizations.of(context), error))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(itemDetailsControllerProvider(widget.args));
    final hints = state.visibleHints.toSet();
    final draft = state.draft;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellStepHeader(
            step: 1,
            title: l10n.itemDetailsTitle,
            subtitle: l10n.itemDetailsSubtitleManual,
            aiNotice: state.aiFilled ? l10n.itemDetailsAiBanner : null,
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.sell),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _Section(
                  label: l10n.itemTitleLabel,
                  isField: true,
                  child: AppTextField(
                    controller: _title,
                    hint: l10n.itemTitleHint,
                    maxLength: ListingDetailsRules.maxTitle,
                    onChanged: _controller.setTitle,
                  ),
                ),
                _Hint(show: hints.contains(DetailsField.title), text: l10n.itemTitleRequired),
                const SizedBox(height: AppSpacing.md),
                _Section(label: l10n.itemCategoryLabel, child: _CategoryChips(args: widget.args)),
                _Hint(show: hints.contains(DetailsField.category), text: l10n.itemCategoryRequired),
                const SizedBox(height: AppSpacing.md),
                _Section(
                  label: l10n.itemConditionLabel,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 0,
                    children: [
                      for (final condition in ListingCondition.values)
                        OptionChip(
                          label: _conditionLabel(l10n, condition),
                          selected: draft.condition == condition,
                          tone: OptionChipTone.success,
                          onTap: () => _controller.setCondition(condition),
                        ),
                    ],
                  ),
                ),
                _Hint(
                    show: hints.contains(DetailsField.condition), text: l10n.itemConditionRequired),
                const SizedBox(height: AppSpacing.md),
                _Section(
                  label: l10n.itemDescriptionLabel,
                  isField: true,
                  child: AppTextField(
                    controller: _description,
                    hint: l10n.itemDescriptionHint,
                    maxLines: 4,
                    maxLength: ListingDetailsRules.maxDescription,
                    keyboardType: TextInputType.multiline,
                    onChanged: _controller.setDescription,
                  ),
                ),
                _Hint(
                    show: hints.contains(DetailsField.description),
                    text: l10n.itemDescriptionRequired),
                const SizedBox(height: AppSpacing.md),
                _Section(label: l10n.itemLocationLabel, child: const _LocationRow()),
                const SizedBox(height: AppSpacing.md),
                _Section(
                  label: l10n.itemPriceLabel,
                  isField: true,
                  child: AppTextField(
                    controller: _price,
                    prefixText: '₹ ',
                    prefixStyle: _priceStyle.copyWith(color: AppColors.brandLink),
                    textStyle: _priceStyle,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    onChanged: _controller.setPrice,
                  ),
                ),
                _Hint(show: hints.contains(DetailsField.price), text: l10n.itemPriceInvalid),
                const SizedBox(height: AppSpacing.sm),
                _InfoCard.note(text: l10n.itemPriceNote),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.brandBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!draft.isValid) ...[
                      Text(l10n.itemFillMissing,
                          style: AppTextStyles.hint, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    BrandGradientButton(
                      label: l10n.itemChooseListingPlan,
                      trailingIcon: Icons.chevron_right_rounded,
                      isLoading: state.isSaving,
                      onPressed: state.canContinue ? () => unawaited(_continue()) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _conditionLabel(AppLocalizations l10n, ListingCondition condition) {
  return switch (condition) {
    ListingCondition.brandNew => l10n.itemConditionNew,
    ListingCondition.likeNew => l10n.itemConditionLikeNew,
    ListingCondition.good => l10n.itemConditionGood,
    ListingCondition.fair => l10n.itemConditionFair,
    ListingCondition.poor => l10n.itemConditionPoor,
  };
}

/// Price typed large and bold, like the Figma Make price block.
final TextStyle _priceStyle = AppTextStyles.input.copyWith(
  fontSize: 24,
  height: 32 / 24,
  fontWeight: FontWeight.w700,
);

/// Small upper-case label above a control (Figma Make). Text fields are named for screen readers
/// by the field itself; other groups use it as a heading.
class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isField;

  const _Section({required this.label, required this.child, this.isField = false});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      style: AppTextStyles.label.copyWith(letterSpacing: 0.8),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isField ? ExcludeSemantics(child: text) : Semantics(header: true, child: text),
        const SizedBox(height: AppSpacing.sm),
        isField ? Semantics(label: label, child: child) : child,
      ],
    );
  }
}

/// The reason a field is not valid yet, shown only once the seller has worked on it.
class _Hint extends StatelessWidget {
  final bool show;
  final String text;

  const _Hint({required this.show, required this.text});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: FieldError(text: text),
    );
  }
}

/// Tinted message card: the blue AI banner or the amber price note.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color fill;
  final Color border;
  final TextStyle style;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.fill,
    required this.border,
    required this.style,
    required this.text,
  });

  factory _InfoCard.note({required String text}) => _InfoCard(
        icon: Icons.schedule_rounded,
        iconColor: AppColors.sellSparkle,
        fill: AppColors.sellNoteTint,
        border: AppColors.sellNoteBorder,
        style: AppTextStyles.bodySecondary,
        text: text,
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: iconColor)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  final ItemDetailsArgs args;

  const _CategoryChips({required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(itemDetailsControllerProvider(args)).draft.categorySlug;
    final controller = ref.read(itemDetailsControllerProvider(args).notifier);

    return categories.when(
      loading: () => Semantics(
        label: l10n.loading,
        child: const LinearProgressIndicator(),
      ),
      error: (error, stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldError(text: l10n.homeCategoriesFailed),
          TextButton(
            onPressed: () => ref.invalidate(categoriesProvider),
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
      data: (items) => CategoryChips(
        categories: items,
        selectedId: selected,
        onSelected: controller.setCategory,
        othersLabel: l10n.itemCategoryOthers,
        closeLabel: l10n.commonClose,
      ),
    );
  }
}

/// The place chosen on Home (area and city, never coordinates). When none is known yet, the same
/// prompt and actions as Home are offered.
class _LocationRow extends ConsumerWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeLocationControllerProvider).value;
    final controller = ref.read(homeLocationControllerProvider.notifier);

    if (state is LocationNeeded) {
      return LocationPrompt(
        need: state.reason,
        onUseLocation: controller.useDeviceLocation,
        onOpenSettings: controller.openSettings,
        onUseSaved: () => showSavedLocationDialog(context),
      );
    }
    if (state is! LocationKnown) {
      return Semantics(label: l10n.loading, child: const LinearProgressIndicator());
    }
    final place = state.location;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandControlBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.location_on_outlined, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.title, style: AppTextStyles.cardTitle),
                  Text(place.subtitle, style: AppTextStyles.hint),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showLocationSheet(context),
              child: Text(l10n.itemLocationChange),
            ),
          ],
        ),
      ),
    );
  }
}
