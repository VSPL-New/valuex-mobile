import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../calls/domain/call.dart';
import '../../../calls/presentation/call_starter.dart';
import '../../../communication_safety/data/communication_safety_repository.dart';
import '../../../communication_safety/domain/communication_safety.dart';
import '../../../communication_safety/presentation/widgets/block_confirmation_dialog.dart';
import '../../../communication_safety/presentation/widgets/report_sheet.dart';
import '../../domain/chat.dart';
import 'chat_avatar.dart';

enum _ThreadAction { block, reportUser, reportThread }

/// The top of a conversation (US-013): back, the other person's avatar and name, the listing title
/// as a tappable subtitle, and Call and Video, which ring the seller when the viewer is the buyer
/// (US-014, US-015) and stay disabled for the seller.
/// The menu blocks or reports the person, or reports the conversation.
class ThreadHeader extends ConsumerWidget {
  final ChatThread thread;
  final VoidCallback onBack;
  final VoidCallback onOpenListing;

  const ThreadHeader({
    super.key,
    required this.thread,
    required this.onBack,
    required this.onOpenListing,
  });

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmBlockUser(context)) return;
    String message;
    try {
      await ref.read(communicationSafetyRepositoryProvider).block(thread.counterpart.userId);
      message = l10n.blockUserDone;
    } on Object {
      message = l10n.blockUserFailed;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _report(BuildContext context, ReportTarget target, String targetId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showReportSheet(context, target: target, targetId: targetId);
    if (!sent) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.reportDone)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // A call goes from the buyer to the seller, and not into a conversation nobody can write in.
    final canCall = thread.isBuyer && thread.canSend;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brandBackground,
        border: Border(bottom: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              SquareBackButton(onPressed: onBack),
              const SizedBox(width: AppSpacing.sm),
              // The avatar is decorative, so on a narrow phone the room goes to the name.
              if (MediaQuery.sizeOf(context).width >= 360) ...[
                ChatAvatar(initial: thread.counterpart.initial, size: 44, circle: true),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        thread.counterpart.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(color: AppColors.brandForeground),
                      ),
                    ),
                    InkWell(
                      onTap: onOpenListing,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
                        child: Semantics(
                          button: true,
                          label: l10n.chatListingOpen(thread.listing.title),
                          excludeSemantics: true,
                          child: Text(
                            thread.listing.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _RoundAction(
                icon: Icons.call_outlined,
                label: l10n.chatCallAction,
                onPressed: canCall
                    ? () => startCall(
                          context,
                          ref,
                          listingId: thread.listing.listingId,
                          type: CallType.voice,
                        )
                    : null,
              ),
              _RoundAction(
                icon: Icons.videocam_outlined,
                label: l10n.chatVideoAction,
                onPressed: canCall
                    ? () => startCall(
                          context,
                          ref,
                          listingId: thread.listing.listingId,
                          type: CallType.video,
                        )
                    : null,
              ),
              PopupMenuButton<_ThreadAction>(
                tooltip: l10n.userSafetyMenu,
                icon: const Icon(Icons.more_vert),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onSelected: (action) => switch (action) {
                  _ThreadAction.block => _block(context, ref),
                  _ThreadAction.reportUser =>
                    _report(context, ReportTarget.user, thread.counterpart.userId),
                  _ThreadAction.reportThread =>
                    _report(context, ReportTarget.thread, thread.threadId),
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: _ThreadAction.block, child: Text(l10n.blockUserAction)),
                  PopupMenuItem(
                    value: _ThreadAction.reportUser,
                    child: Text(l10n.reportUserAction),
                  ),
                  PopupMenuItem(
                    value: _ThreadAction.reportThread,
                    child: Text(l10n.chatMenuReportConversation),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round control; without an action it looks disabled and is announced as such.
class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _RoundAction({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: IconButton.styleFrom(backgroundColor: AppColors.brandMuted),
          icon: Icon(icon, size: 20, color: AppColors.brandForeground),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
