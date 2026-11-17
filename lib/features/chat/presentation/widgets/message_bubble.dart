import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat.dart';
import 'chat_time.dart';

/// The words for a delivery state, spoken and shown under the caller's own messages.
String chatStatusLabel(AppLocalizations l10n, MessageStatus? status) => switch (status) {
      MessageStatus.sending => l10n.chatStatusSending,
      MessageStatus.failed => l10n.chatStatusFailed,
      MessageStatus.sent => l10n.chatStatusSent,
      MessageStatus.delivered => l10n.chatStatusDelivered,
      MessageStatus.read => l10n.chatStatusRead,
      null => '',
    };

/// One message of a person (US-013): white for the other person, the brand gradient for the caller.
/// The time sits inside the bubble; the caller's messages also show Sent, Delivered or Read, and a
/// message that failed to send shows Retry and Delete. The bubble is spoken as one sentence.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String counterpartName;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  const MessageBubble({
    super.key,
    required this.message,
    required this.counterpartName,
    this.onRetry,
    this.onDiscard,
  });

  static const double _radius = 20;
  static const double _tail = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = message.fromMe;
    final failed = message.status == MessageStatus.failed;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final time = chatClock(context, message.createdAt);
    final status = mine ? chatStatusLabel(l10n, message.status) : '';
    final isImage = message.type == ChatMessageType.image;
    final spoken = isImage
        ? (mine ? l10n.chatPhotoMine(time, status) : l10n.chatPhotoTheirs(counterpartName, time))
        : (mine
            ? l10n.chatBubbleMine(message.body ?? '', time, status)
            : l10n.chatBubbleTheirs(counterpartName, message.body ?? '', time));
    final foreground = mine ? AppColors.brandOnPrimary : AppColors.brandForeground;
    final muted = mine ? AppColors.brandOnPrimary : AppColors.brandMutedText;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(_radius),
      topRight: const Radius.circular(_radius),
      bottomLeft: Radius.circular(mine ? _radius : _tail),
      bottomRight: Radius.circular(mine ? _tail : _radius),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: spoken,
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: mine ? AppGradients.brand : null,
                  color: mine ? null : AppColors.brandSurface,
                  borderRadius: radius,
                  border: mine ? null : Border.all(color: AppColors.brandBorder),
                  boxShadow: mine
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x14135CFF),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isImage)
                        _Picture(message: message)
                      else
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            message.body ?? '',
                            style: AppTextStyles.body.copyWith(color: foreground),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        mine && status.isNotEmpty && !failed ? '$time  $status' : time,
                        style: AppTextStyles.caption.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    l10n.chatStatusFailed,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandError),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.brandLink,
                    ),
                    child: Text(l10n.chatRetry),
                  ),
                  TextButton(
                    onPressed: onDiscard,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.brandError,
                    ),
                    child: Text(l10n.chatDiscard),
                  ),
                ],
              ),
            ),
          if (message.flags.isNotEmpty && !mine)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.chatSafetyTip,
                style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
              ),
            ),
        ],
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  final ChatMessage message;

  const _Picture({required this.message});

  static const double _size = 220;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bytes = message.pendingImage;
    final url = message.imageUrl;
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes, width: _size, fit: BoxFit.cover);
    } else if (url != null) {
      image = Image.network(
        url,
        width: _size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _placeholder(l10n.chatPhotoUnavailable),
      );
    } else {
      image = _placeholder(l10n.chatPhotoUnavailable);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.lg), child: image);
  }

  Widget _placeholder(String text) => Container(
        width: _size,
        height: 120,
        alignment: Alignment.center,
        color: AppColors.brandMuted,
        child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground)),
      );
}
