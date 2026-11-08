import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/listing_preview.dart';
import '../../domain/listing_preview_fields.dart';
import '../../domain/my_listings.dart';
import '../item_details_screen.dart' show listingConditionLabel;
import 'listing_status_badge.dart';
import 'preview_actions.dart';
import 'preview_gallery.dart';

/// A saved listing as buyers will see it, read-only (US-123): status banner, photos, summary, the
/// Overview and Details tabs, and the buyer actions switched off. It only shows what it is given;
/// the owner's data is loaded by the screen. Sold Listing Details (US-126) reuses it.
class ListingPreview extends StatefulWidget {
  final ListingPreviewData data;

  /// Asked for when the category's form is missing and the seller taps Retry.
  final VoidCallback? onRetry;

  const ListingPreview({super.key, required this.data, this.onRetry});

  @override
  State<ListingPreview> createState() => _ListingPreviewState();
}

class _ListingPreviewState extends State<ListingPreview> {
  /// Above this text scale the banner and buyer actions stop being pinned.
  static const double _pinLimit = 1.3;

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = widget.data;
    final fields = projectPreviewFields(
      data,
      PreviewLabels(
        yes: l10n.itemYes,
        no: l10n.itemNo,
        notProvided: l10n.previewNotProvided,
        quantity: l10n.previewQuantity,
        conditionNotes: l10n.previewConditionNotes,
        formatDate: (date) =>
            DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date),
      ),
    );
    final page = [
      PreviewGallery(images: data.images),
      _Summary(data: data),
      _Tabs(selected: _tab, onSelected: (tab) => setState(() => _tab = tab)),
      Padding(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: _tab == 0
            ? _OverviewPanel(data: data, fields: fields, onRetry: widget.onRetry)
            : _DetailsPanel(fields: fields, onRetry: widget.onRetry),
      ),
    ];
    // At large text the pinned banner and buttons would leave no room for the listing, so they
    // scroll with it.
    final large = MediaQuery.textScalerOf(context).scale(16) / 16 > _pinLimit;
    if (large) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_StatusBanner(data: data), ...page, const PreviewActions()],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBanner(data: data),
        Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: page),
          ),
        ),
        const PreviewActions(),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final ListingPreviewData data;

  const _StatusBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badge = ListingBadge.forStatus(data.status);
    final reason = data.reviewReason;
    final failed = badge == ListingBadge.needsChanges || badge == ListingBadge.rejected;
    return Semantics(
      container: true,
      liveRegion: true,
      child: ColoredBox(
        color: failed ? AppColors.brandErrorTint : AppColors.brandSurfaceTint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListingStatusBadge(badge: badge),
              const SizedBox(height: AppSpacing.xs),
              Text(_message(l10n, badge), style: AppTextStyles.bodySecondary),
              if (failed && reason != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.previewReason(reason),
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.brandForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _message(AppLocalizations l10n, ListingBadge badge) => switch (badge) {
        ListingBadge.draft => l10n.previewStatusDraft,
        ListingBadge.processingPayment => l10n.previewStatusProcessing,
        ListingBadge.underReview => l10n.previewStatusUnderReview,
        ListingBadge.needsChanges => l10n.previewStatusNeedsChanges,
        ListingBadge.active => l10n.previewStatusActive,
        ListingBadge.sold => l10n.previewStatusSold,
        ListingBadge.expired => l10n.previewStatusExpired,
        ListingBadge.rejected => l10n.previewStatusRejected,
        ListingBadge.unavailable => l10n.previewStatusUnavailable,
      };
}

class _Summary extends StatelessWidget {
  final ListingPreviewData data;

  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schema = data.schema;
    final category = data.category;
    final path = category == null
        ? ''
        : (category.path.isEmpty ? category.name : category.path.map((i) => i.name).join(' > '));
    final condition = data.condition;
    final showCondition = condition != null && (schema?.common.conditionVisible ?? true);
    final showNegotiable = data.negotiable == true && (schema?.common.negotiableVisible ?? true);
    final price = data.price;
    final planBadge = data.planBadge;
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (path.isNotEmpty) Text(path, style: AppTextStyles.hint),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    data.title.isEmpty ? l10n.myListingsUntitled : data.title,
                    style: AppTextStyles.heading2,
                  ),
                ),
              ),
              if (showCondition) ...[
                const SizedBox(width: AppSpacing.sm),
                _Chip(text: listingConditionLabel(l10n, condition)),
              ],
            ],
          ),
          if (price != null || showNegotiable) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (price != null)
                  Text(
                    Formatters.money(price),
                    style: AppTextStyles.heading2.copyWith(color: AppColors.brandLink),
                  ),
                if (showNegotiable) Text(l10n.previewNegotiable, style: AppTextStyles.hint),
              ],
            ),
          ],
          if (planBadge != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _Chip(text: l10n.previewPlanBadge(planBadge)),
            ),
          ],
          if (data.city.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.place_outlined, size: 16, color: AppColors.brandMutedText),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(data.city, style: AppTextStyles.hint)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _Tabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brandDivider)),
      ),
      child: Row(
        children: [
          Expanded(
              child: _Tab(
                  label: l10n.previewOverview,
                  selected: selected == 0,
                  onTap: () => onSelected(0))),
          Expanded(
              child: _Tab(
                  label: l10n.previewDetails, selected: selected == 1, onTap: () => onSelected(1))),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.brandPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: selected ? AppTextStyles.linkSmall : AppTextStyles.bodySecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final ListingPreviewData data;
  final PreviewFields fields;
  final VoidCallback? onRetry;

  const _OverviewPanel({required this.data, required this.fields, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final description = data.description.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(l10n.previewAbout),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description.isEmpty ? l10n.previewNotProvided : description,
          style: description.isEmpty ? AppTextStyles.hint : AppTextStyles.body,
        ),
        if (fields.overview.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Heading(l10n.previewKeyDetails),
          const SizedBox(height: AppSpacing.xs),
          _Rows(rows: fields.overview),
        ],
        if (fields.schemaUnavailable) ...[
          const SizedBox(height: AppSpacing.lg),
          _Unavailable(onRetry: onRetry),
        ],
      ],
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  final PreviewFields fields;
  final VoidCallback? onRetry;

  const _DetailsPanel({required this.fields, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(l10n.previewItemDetails),
        const SizedBox(height: AppSpacing.xs),
        if (fields.details.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(l10n.previewNoAdditionalDetails, style: AppTextStyles.hint),
          )
        else
          _Rows(rows: fields.details),
        if (fields.schemaUnavailable) ...[
          const SizedBox(height: AppSpacing.lg),
          _Unavailable(onRetry: onRetry),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(text, style: AppTextStyles.sectionTitle));
}

class _Rows extends StatelessWidget {
  final List<PreviewRow> rows;

  const _Rows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.brandDivider),
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(rows[i].label, style: AppTextStyles.bodySecondary)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      style: rows[i].missing ? AppTextStyles.hint : AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  final VoidCallback? onRetry;

  const _Unavailable({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.previewDetailsUnavailable, style: AppTextStyles.bodySecondary),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.commonRetry, style: AppTextStyles.link),
          ),
      ],
    );
  }
}
