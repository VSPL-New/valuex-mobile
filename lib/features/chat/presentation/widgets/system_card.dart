import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat.dart';

/// A card the system writes into the conversation. The listing card shows what the chat is about
/// at the moment it started; offer and call cards (later stories) show a neutral line until they
/// have their own look.
class SystemCard extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onOpenListing;

  const SystemCard({super.key, required this.message, this.onOpenListing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isListing = message.type == ChatMessageType.listingContext;
    final title = message.payload['title'] as String? ?? '';
    final price = message.payload['price'];
    final label = isListing ? l10n.chatListingCardLabel(title) : l10n.chatCardUpdate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Semantics(
          container: true,
          button: isListing && onOpenListing != null,
          label: label,
          excludeSemantics: true,
          onTap: isListing ? onOpenListing : null,
          child: Material(
            color: AppColors.brandSurfaceTint,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: isListing ? onOpenListing : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.86,
                  minHeight: AppSizes.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: isListing
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardTitle
                                  .copyWith(color: AppColors.brandForeground),
                            ),
                            if (price is num)
                              Text(
                                Formatters.currency(price),
                                style:
                                    AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                              ),
                          ],
                        )
                      : Text(
                          l10n.chatCardUpdate,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
