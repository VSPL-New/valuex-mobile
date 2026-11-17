import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat.dart';
import 'chat_avatar.dart';
import 'chat_time.dart';

/// One conversation in the Chats list (US-013): avatar, name and time, the listing, a preview of
/// the last message, an unread count and a Buying or Selling tag. The row is spoken as one sentence.
class ChatListTile extends StatelessWidget {
  final ChatThread thread;
  final DateTime now;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.thread, required this.now, required this.onTap});

  String _preview(AppLocalizations l10n) {
    final last = thread.lastMessage;
    if (last == null) return l10n.chatPreviewNone;
    final text = last.type == ChatMessageType.image
        ? l10n.chatPreviewPhoto
        : (last.preview ?? l10n.chatCardUpdate);
    return last.fromMe ? l10n.chatPreviewYou(text) : text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ago = chatAgo(context, thread.lastMessage?.at, now);
    final preview = _preview(l10n);
    final unread = thread.unreadCount;
    final spoken = [
      l10n.chatRowLabel(thread.counterpart.displayName, thread.listing.title, preview, ago),
      if (unread > 0) l10n.chatUnreadLabel(unread),
    ].join('. ');
    return Semantics(
      button: true,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatAvatar(initial: thread.counterpart.initial),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.counterpart.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardTitle.copyWith(
                                color: AppColors.brandForeground,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            ago,
                            style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                          ),
                        ],
                      ),
                      Text(
                        thread.listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySecondary.copyWith(
                                color: unread > 0
                                    ? AppColors.brandForeground
                                    : AppColors.brandMutedText,
                                fontWeight: unread > 0 ? FontWeight.w600 : null,
                              ),
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _UnreadChip(count: unread),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        thread.isBuyer ? l10n.chatTagBuying : l10n.chatTagSelling,
                        style: AppTextStyles.caption.copyWith(color: AppColors.brandLink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadChip extends StatelessWidget {
  final int count;

  const _UnreadChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: AppColors.brandLink,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.brandOnPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
