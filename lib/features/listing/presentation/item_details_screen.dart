import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../../home/presentation/widgets/location_prompt.dart';
import '../../home/presentation/widgets/location_sheet.dart';
import '../../home/presentation/widgets/saved_location_dialog.dart';
import '../domain/listing_details.dart';
import '../domain/listing_schema.dart';
import '../domain/plan_selection.dart';
import '../domain/restricted_check.dart';
import 'category_picker_screen.dart';
import 'listing_error_messages.dart';
import 'providers/item_details_controller.dart';
import 'widgets/option_chip.dart';
import 'widgets/restricted_item_dialogs.dart';
import 'widgets/schema_field_input.dart';
import 'widgets/sell_step_header.dart';

/// Sell step 2 of 4 (Figma Make: CreateListingScreen, "details" step, with the price block of the
/// "price" step merged in): title and category first, then the form that category asks for
/// (US-006), location and price. Empty when AI is off; prefilled and editable when AI filled it
/// (US-114).
class ItemDetailsScreen extends ConsumerStatefulWidget {
  final ItemDetailsArgs args;

  const ItemDetailsScreen({super.key, required this.args});

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _conditionNotes;
  late final TextEditingController _price;
  late final TextEditingController _quantity;

  ItemDetailsController get _controller =>
      ref.read(itemDetailsControllerProvider(widget.args).notifier);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(itemDetailsControllerProvider(widget.args)).draft;
    _title = TextEditingController(text: draft.title);
    _description = TextEditingController(text: draft.description);
    _conditionNotes = TextEditingController(text: draft.conditionNotes);
    _price = TextEditingController(text: draft.price);
    _quantity = TextEditingController(text: draft.quantity);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _conditionNotes.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _chooseCategory() async {
    final current = ref.read(itemDetailsControllerProvider(widget.args)).draft.categoryCode;
    final code = await pickCategory(context, selectedCode: current);
    if (code != null && code != current) await _controller.selectCategory(code);
  }

  Future<void> _continue() async {
    final result = await _controller.save();
    if (!mounted) return;
    if (result.saved) {
      await _checkRestricted();
      return;
    }
    _showError(result.error);
  }

  /// US-007: the plan page opens only when the item passes the restricted items policy.
  Future<void> _checkRestricted() async {
    final outcome = await _controller.checkRestricted();
    if (!mounted) return;
    final check = outcome.check;
    if (check == null) {
      _showError(outcome.error);
      return;
    }
    switch (check.result) {
      case RestrictedResult.safe:
        unawaited(context.push(RouteNames.sellPlan, extra: _planArgs()));
      case RestrictedResult.complianceRequired:
        final agreed = await showComplianceDialog(context, check);
        if (!agreed || !mounted) return;
        final error = await _controller.acceptCompliance(check);
        if (!mounted) return;
        if (error == null) {
          unawaited(context.push(RouteNames.sellPlan, extra: _planArgs()));
        } else {
          _showError(error);
        }
      case RestrictedResult.restricted || RestrictedResult.severeViolation:
        final appealed = await showBlockedDialog(
          context,
          check,
          onAppeal: (reason) => _controller.appealRestricted(check, reason),
        );
        if (appealed && mounted) _showMessage(AppLocalizations.of(context).restrictedAppealSent);
      case RestrictedResult.unclear:
        _showMessage(AppLocalizations.of(context).restrictedErrorUnderReview);
    }
  }

  void _showError(Object? error) {
    if (error == null) return;
    _showMessage(listingErrorMessage(AppLocalizations.of(context), error));
  }

  /// The draft and what the plan and review pages repeat back to the seller.
  PlanArgs _planArgs() {
    final state = ref.read(itemDetailsControllerProvider(widget.args));
    final draft = state.draft;
    return PlanArgs(
      listingId: widget.args.listingId,
      summary: ListingSummary(
        title: draft.title,
        categoryPath: state.category?.path.map((item) => item.name).join(' > ') ?? '',
        price: draft.price,
        description: draft.description,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(itemDetailsControllerProvider(widget.args));
    final hints = state.visibleHints.toSet();
    final schema = state.schema;
    final ready = state.schemaStatus == SchemaStatus.ready && schema != null;

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
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section(
                        label: l10n.itemTitleLabel,
                        icon: Icons.edit_outlined,
                        isField: true,
                        child: AppTextField(
                          controller: _title,
                          hint: l10n.itemTitleHint,
                          maxLength: ListingDetailsRules.maxTitle,
                          onChanged: _controller.setTitle,
                        ),
                      ),
                      _AiMark(show: state.isAiGenerated(DetailsField.title)),
                      _Hint(show: hints.contains(DetailsField.title), text: l10n.itemTitleRequired),
                      const SizedBox(height: AppSpacing.md),
                      _Section(
                        label: l10n.itemCategoryLabel,
                        icon: Icons.grid_view_rounded,
                        child: _CategoryRow(state: state, onTap: _chooseCategory),
                      ),
                      _AiMark(show: state.isAiGenerated(DetailsField.category)),
                      _Hint(
                          show: hints.contains(DetailsField.category),
                          text: l10n.itemCategoryRequired),
                    ],
                  ),
                ),
                if (state.schemaStatus == SchemaStatus.loading)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Semantics(label: l10n.loading, child: const LinearProgressIndicator()),
                  ),
                if (state.schemaStatus == SchemaStatus.failed)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _SchemaFailed(
                      error: state.schemaError,
                      onRetry: () => unawaited(_controller.retryCategory()),
                    ),
                  ),
                if (ready) ..._form(l10n, state, schema, hints),
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
                    if (!state.draft.isValid(schema) || !ready) ...[
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

  /// Everything below the category once its form is known.
  List<Widget> _form(
    AppLocalizations l10n,
    ItemDetailsState state,
    ListingSchema schema,
    Set<DetailsField> hints,
  ) {
    final draft = state.draft;
    final common = schema.common;
    final attributeHints = state.visibleAttributeHints;
    final shown = [
      for (final field in schema.fields)
        if (!field.isMore && schema.isRequired(field, draft.attributes)) field,
    ];
    final optional = [
      for (final field in schema.fields)
        if (field.isMore || !schema.isRequired(field, draft.attributes)) field,
    ];

    Widget attribute(SchemaField field) => _AttributeField(
          key: ValueKey('${schema.category.code}:${field.key}'),
          field: field,
          value: draft.attributes[field.key],
          required: schema.isRequired(field, draft.attributes),
          showHint: attributeHints.contains(field.key),
          aiGenerated: state.isAiAttribute(field.key),
          verify: state.needsVerification(field.key),
          onChanged: (value) => _controller.setAttribute(field.key, value),
        );

    return [
      const SizedBox(height: AppSpacing.md),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (common.conditionVisible) ...[
              _Section(
                label: l10n.itemConditionLabel,
                icon: Icons.verified_outlined,
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
              _AiMark(show: state.isAiGenerated(DetailsField.condition)),
              _Hint(show: hints.contains(DetailsField.condition), text: l10n.itemConditionRequired),
              const SizedBox(height: AppSpacing.md),
              _Section(
                label: l10n.itemConditionNotesLabel,
                icon: Icons.build_outlined,
                isField: true,
                child: AppTextField(
                  controller: _conditionNotes,
                  hint: l10n.itemConditionNotesHint,
                  maxLines: 2,
                  maxLength: ListingDetailsRules.maxConditionNotes,
                  keyboardType: TextInputType.multiline,
                  onChanged: _controller.setConditionNotes,
                ),
              ),
              _AiMark(show: state.isAiGenerated(DetailsField.conditionNotes)),
              _Hint(
                  show: hints.contains(DetailsField.conditionNotes),
                  text: l10n.itemConditionNotesRequired),
              const SizedBox(height: AppSpacing.md),
            ],
            _Section(
              label: l10n.itemDescriptionLabel,
              icon: Icons.notes_rounded,
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
            _AiMark(show: state.isAiGenerated(DetailsField.description)),
            _Hint(
                show: hints.contains(DetailsField.description), text: l10n.itemDescriptionRequired),
          ],
        ),
      ),
      if (shown.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.itemAboutTitle.toUpperCase(),
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.brandForeground, letterSpacing: 0.8)),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final field in shown) attribute(field),
            ],
          ),
        ),
      ],
      if (optional.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        SoftCard(
          child: _Collapsible(
            title: l10n.itemMoreDetails,
            subtitle: l10n.itemMoreDetailsHint,
            initiallyOpen: optional.any((field) => state.isAiAttribute(field.key)),
            children: [for (final field in optional) attribute(field)],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              label: l10n.itemLocationLabel,
              icon: Icons.place_outlined,
              child: const _LocationRow(),
            ),
            if (!common.priceDerived) ...[
              const SizedBox(height: AppSpacing.md),
              _Section(
                label: l10n.itemPriceLabel,
                icon: Icons.currency_rupee_rounded,
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
            ],
            if (common.negotiableVisible) ...[
              const SizedBox(height: AppSpacing.md),
              _Section(
                label: l10n.itemNegotiableLabel,
                icon: Icons.handshake_outlined,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    OptionChip(
                      label: l10n.itemYes,
                      selected: draft.negotiable == true,
                      onTap: () => _controller.setNegotiable(true),
                    ),
                    OptionChip(
                      label: l10n.itemNo,
                      selected: draft.negotiable == false,
                      onTap: () => _controller.setNegotiable(false),
                    ),
                  ],
                ),
              ),
              _Hint(
                  show: hints.contains(DetailsField.negotiable), text: l10n.itemNegotiableRequired),
            ],
            if (common.quantityVisible) ...[
              const SizedBox(height: AppSpacing.md),
              _Section(
                label: l10n.itemQuantityLabel,
                icon: Icons.numbers_rounded,
                isField: true,
                child: AppTextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _controller.setQuantity,
                ),
              ),
              _Hint(show: hints.contains(DetailsField.quantity), text: l10n.itemQuantityInvalid),
            ],
            const SizedBox(height: AppSpacing.sm),
            _InfoCard.note(text: l10n.itemPriceNote),
          ],
        ),
      ),
    ];
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

/// Upper-case label with a small icon tile above a control (Figma Make labels). Text fields are
/// named for screen readers by the field itself; other groups use it as a heading.
class _Section extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final bool isField;

  const _Section({
    required this.label,
    required this.icon,
    required this.child,
    this.isField = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      style: AppTextStyles.label.copyWith(color: AppColors.brandForeground, letterSpacing: 0.8),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon: icon, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child:
                    isField ? ExcludeSemantics(child: text) : Semantics(header: true, child: text)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        isField ? Semantics(label: label, child: child) : child,
      ],
    );
  }
}

/// Sparkle and "AI generated" under a field that still holds what AI suggested; it goes away as
/// soon as the seller edits that field.
class _AiMark extends StatelessWidget {
  final bool show;

  const _AiMark({required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.auto_awesome, size: 16, color: AppColors.brandLink),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).itemAiGenerated,
            style: AppTextStyles.hint.copyWith(color: AppColors.brandForeground),
          ),
        ],
      ),
    );
  }
}

/// "Please verify" under an AI value that AI was less sure about; an icon and words, not only
/// colour, and it goes away once the seller edits the value.
class _VerifyHint extends StatelessWidget {
  final bool show;

  const _VerifyHint({required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brandForeground),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).itemPleaseVerify,
            style: AppTextStyles.hint.copyWith(color: AppColors.brandForeground),
          ),
        ],
      ),
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

/// Tinted message card: the amber price note.
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

/// The chosen category with its path and a button to change it, or a button to choose one.
class _CategoryRow extends StatelessWidget {
  final ItemDetailsState state;
  final VoidCallback onTap;

  const _CategoryRow({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final category = state.category;
    if (category == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.search_rounded),
          label: Text(l10n.itemCategoryChoose),
        ),
      );
    }
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTextStyles.cardTitle),
                  if (category.parentsLabel.isNotEmpty)
                    Text(category.parentsLabel, style: AppTextStyles.hint),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: Text(l10n.itemCategoryChange)),
          ],
        ),
      ),
    );
  }
}

/// A heading that shows or hides the fields below it. Built on a plain gesture rather than an
/// expansion tile, whose list tile would sit under the card's background.
class _Collapsible extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Starts open, e.g. when AI filled something inside.
  final bool initiallyOpen;

  const _Collapsible({
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyOpen = false,
  });

  @override
  State<_Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<_Collapsible> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label: widget.title,
          excludeSemantics: true,
          onTap: () => setState(() => _open = !_open),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTextStyles.cardTitle),
                        Text(widget.subtitle, style: AppTextStyles.hint),
                      ],
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.brandForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: AppSpacing.sm),
          ...widget.children,
        ],
      ],
    );
  }
}

/// Shown when the form for the chosen category could not be loaded.
class _SchemaFailed extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _SchemaFailed({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = error;
    final specific = listingCodeMessage(l10n, failure is ApiError ? failure.code : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldError(text: specific ?? l10n.itemSchemaFailed),
        TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
      ],
    );
  }
}

/// One category-specific question: its label, the input for its type and why it is not valid.
class _AttributeField extends StatelessWidget {
  final SchemaField field;
  final Object? value;
  final bool required;
  final bool showHint;

  /// The value still is what AI suggested.
  final bool aiGenerated;

  /// AI was less sure about this value; the seller is asked to check it.
  final bool verify;
  final ValueChanged<Object?> onChanged;

  const _AttributeField({
    super.key,
    required this.field,
    required this.value,
    required this.required,
    required this.showHint,
    required this.aiGenerated,
    required this.verify,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = field.unit;
    final label = unit == null || unit.isEmpty ? field.label : '${field.label} ($unit)';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              required ? '$label *' : label,
              style: AppTextStyles.label.copyWith(color: AppColors.brandForeground),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SchemaFieldInput(field: field, value: value, onChanged: onChanged),
          _AiMark(show: aiGenerated),
          _VerifyHint(show: verify),
          _Hint(
            show: showHint,
            text: isBlankValue(value)
                ? l10n.itemFieldRequired(field.label)
                : l10n.itemFieldInvalid(field.label),
          ),
        ],
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
