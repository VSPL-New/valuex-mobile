import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/my_listings.dart';
import 'listing_status_badge.dart';

/// One listing on My Listings (US-010): photo, plan and status, title, price, views and chats.
/// The whole card opens the listing; the edit icon (top right) and the trash button (bottom right)
/// are separate controls, shown only when the server says the action is allowed.
class MyListingCard extends StatelessWidget {
  static const double thumbnailSize = 84;

  final MyListingItem item;
  final VoidCallback onOpen;
  final VoidCallback? onPreview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Marks a property Sold, Rented or Leased; shown only when the server offers [MyListingItem.closeOutcome].
  final VoidCallback? onClose;

  const MyListingCard({
    super.key,
    required this.item,
    required this.onOpen,
    this.onPreview,
    this.onEdit,
    this.onDelete,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = item.title.isEmpty ? l10n.myListingsUntitled : item.title;
    final radius = BorderRadius.circular(AppRadius.xl);
    return DecoratedBox(
      decoration: SoftCard.decoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        // Stretches the action column to the card's height; cards are few (a page of 20).
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: radius,
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: thumbnailSize,
                          height: thumbnailSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: AppImage(source: item.thumbnailUrl ?? '', cacheWidth: 252),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _Details(
                            item: item,
                            title: title,
                            onPreview: onPreview,
                            onClose: onClose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs, top: AppSpacing.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          tooltip: l10n.myListingsEdit(title),
                          onPressed: onEdit,
                          color: AppColors.brandLink,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      const Spacer(),
                      if (onDelete != null)
                        IconButton(
                          tooltip: l10n.myListingsDelete(title),
                          onPressed: onDelete,
                          color: AppColors.brandError,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final MyListingItem item;
  final String title;
  final VoidCallback? onPreview;
  final VoidCallback? onClose;

  const _Details({
    required this.item,
    required this.title,
    this.onPreview,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final planName = item.planName;
    final price = item.price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (planName != null && planName.isNotEmpty)
              Text(l10n.myListingsPlan(planName), style: AppTextStyles.caption),
            ListingStatusBadge(badge: item.badge, closedOutcome: item.closedOutcome),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(title, style: AppTextStyles.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (price != null) Text(Formatters.money(price), style: AppTextStyles.cardPrice),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _Count(icon: Icons.visibility_outlined, text: l10n.myListingsViews(item.viewCount)),
            _Count(
                icon: Icons.chat_bubble_outline_rounded,
                text: l10n.myListingsChats(item.chatCount)),
          ],
        ),
        if (onClose != null && item.closeOutcome != null)
          _CloseLink(
            title: title,
            outcome: closedOutcomeLabel(l10n, item.closeOutcome!),
            onPressed: onClose!,
          ),
        if (onPreview != null)
          Semantics(
            button: true,
            label: l10n.myListingsPreviewLabel(title),
            excludeSemantics: true,
            child: InkWell(
              onTap: onPreview,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(l10n.myListingsPreview, style: AppTextStyles.linkSmall),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Count({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 16, color: AppColors.brandMutedText)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: AppTextStyles.hint)),
      ],
    );
  }
}

/// "Mark as Sold, Rented or Leased" for a published property (US-118).
class _CloseLink extends StatelessWidget {
  final String title;
  final String outcome;
  final VoidCallback onPressed;

  const _CloseLink({required this.title, required this.outcome, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.myListingsMarkClosed(title, outcome),
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l10n.myListingsCloseConfirm(outcome), style: AppTextStyles.linkSmall),
          ),
        ),
      ),
    );
  }
}
