import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/realtime_reconnecting_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../listing/data/photo_source.dart';
import '../domain/chat.dart';
import 'chat_error_messages.dart';
import 'providers/chat_thread_controller.dart';
import 'widgets/blocked_message_sheet.dart';
import 'widgets/chat_time.dart';
import 'widgets/composer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/safety_banner.dart';
import 'widgets/system_card.dart';
import 'widgets/thread_header.dart';

/// One conversation with a buyer or seller (US-013). Messages are ordered by the server's
/// sequence, a message the user sends shows at once, and news arrives while the screen is open.
class ChatThreadScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatThreadScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  static const double _bottomSlack = 80;

  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _unreadKey = GlobalKey();
  bool _atBottom = true;
  bool _showNewMessages = false;
  bool _scrolledToUnread = false;
  int _lastSeen = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _text.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  /// Lets the other person see "typing…" while the field holds text.
  void _onTextChanged() => _controller.typingChanged(_text.text.trim().isNotEmpty);

  void _onScroll() {
    final atBottom = !_scroll.hasClients || _scroll.offset < _bottomSlack;
    if (atBottom != _atBottom || (atBottom && _showNewMessages)) {
      setState(() {
        _atBottom = atBottom;
        if (atBottom) _showNewMessages = false;
      });
    }
  }

  void _jumpToNewest() {
    if (!_scroll.hasClients) return;
    unawaited(
        _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut));
  }

  /// A message from the other person arriving while the user reads older ones shows the chip.
  void _onState(ChatThreadState? previous, ChatThreadState next) {
    final newest = next.lastSeq;
    final wasEmpty = _lastSeen == 0;
    final grew = newest > _lastSeen;
    _lastSeen = newest;
    if (wasEmpty || !grew) return;
    final fromOther = next.messages.any((m) => m.seq > 0 && m.seq == newest && !m.fromMe);
    if (fromOther && !_atBottom) setState(() => _showNewMessages = true);
  }

  void _scrollToUnread() {
    if (_scrolledToUnread) return;
    _scrolledToUnread = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _unreadKey.currentContext;
      if (context != null) {
        unawaited(Scrollable.ensureVisible(context, alignment: 0.3));
      }
    });
  }

  ChatThreadController get _controller =>
      ref.read(chatThreadControllerProvider(widget.threadId).notifier);

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send(String text) async {
    _text.clear();
    await _handle(await _controller.sendText(text), text);
  }

  Future<void> _handle(SendOutcome outcome, String text, {bool afterOverride = false}) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case SendStored() || SendQueued():
        return;
      case SendRefused(:final error):
        if (_text.text.isEmpty && text.isNotEmpty) _text.text = text;
        _snack(chatSendErrorMessage(l10n, error, afterOverride: afterOverride));
      case SendFlagged():
        await _askAboutBlocked(outcome);
    }
  }

  /// The blocked-message flow (decision D13): edit it, or deliver it after the user agrees.
  Future<void> _askAboutBlocked(SendFlagged flagged) async {
    final choice = await showBlockedMessageSheet(context, text: flagged.body, terms: flagged.terms);
    if (!mounted) return;
    if (choice != BlockedMessageChoice.deliver) {
      if (_text.text.isEmpty) _text.text = flagged.body;
      return;
    }
    if (!await confirmPolicyAgreement(context)) {
      if (!mounted) return;
      await _askAboutBlocked(flagged);
      return;
    }
    final outcome = await _controller.sendText(
      flagged.body,
      clientMessageId: flagged.clientMessageId,
      agreed: true,
    );
    await _handle(outcome, flagged.body, afterOverride: true);
  }

  Future<void> _attach() async {
    final l10n = AppLocalizations.of(context);
    final kind = await showModalBottomSheet<PhotoSourceKind>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.chatAttachCamera),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSourceKind.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chatAttachGallery),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSourceKind.gallery),
            ),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    final source = ref.read(chatPhotoSourceProvider);
    try {
      final picked = await source.pick(kind, limit: 1);
      if (picked.isEmpty || !mounted) return;
      final photo = picked.first;
      final inspection = await source.inspect(photo.bytes);
      if (!mounted) return;
      if (inspection == null) {
        _snack(l10n.chatErrorImageInvalid);
        return;
      }
      final outcome = await _controller.sendImage(
        bytes: photo.bytes,
        fileName: photo.name,
        contentType: inspection.contentType,
        width: inspection.width,
        height: inspection.height,
      );
      await _handle(outcome, '');
    } on PhotoAccessDeniedException {
      if (mounted) _snack(l10n.chatPhotoDenied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = chatThreadControllerProvider(widget.threadId);
    ref.listen(provider, (previous, next) {
      if (next.value case final data?) _onState(previous?.value, data);
    });
    final state = ref.watch(provider);
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: state.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => SafeArea(
          child: ErrorView(
            message: l10n.chatThreadLoadFailed,
            onRetry: () => ref.invalidate(provider),
          ),
        ),
        data: (data) => _body(context, data),
      ),
    );
  }

  Widget _body(BuildContext context, ChatThreadState data) {
    final l10n = AppLocalizations.of(context);
    final thread = data.thread;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThreadHeader(
          thread: thread,
          onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.chats),
          onOpenListing: () => context.push(RouteNames.listingView(thread.listing.listingId)),
          onCallsComingSoon: () => _snack(l10n.chatCallsComingSoon),
        ),
        const SafetyBanner(),
        const RealtimeReconnectingBanner(),
        Expanded(child: _messages(context, data)),
        if (data.typing && thread.canSend) _TypingIndicator(name: thread.counterpart.displayName),
        if (thread.canSend)
          ChatComposer(controller: _text, onSend: _send, onAttach: _attach)
        else
          _ReadOnlyBanner(
            message: readOnlyMessage(
              l10n,
              thread.readOnlyReason ?? ReadOnlyReason.blocked,
            ),
          ),
      ],
    );
  }

  Widget _messages(BuildContext context, ChatThreadState data) {
    final l10n = AppLocalizations.of(context);
    final rows = _rows(context, data);
    if (data.firstUnreadSeq > 0) _scrollToUnread();
    final onlyCard = data.messages.every((m) => m.type.isCard);
    return Stack(
      children: [
        ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          itemCount: rows.length + (data.hasMoreOlder ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == rows.length) {
              return _OlderLoader(
                loading: data.loadingOlder,
                onLoad: () async {
                  final ok = await _controller.loadOlder();
                  if (!ok && mounted) _snack(l10n.chatLoadOlderFailed);
                },
              );
            }
            return rows[rows.length - 1 - index];
          },
        ),
        if (onlyCard)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.chatThreadEmpty,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandMutedText),
              ),
            ),
          ),
        if (_showNewMessages)
          Positioned(
            bottom: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(
              child: ActionChip(
                label: Text(l10n.chatNewMessages),
                avatar: const Icon(Icons.arrow_downward_rounded, size: 16),
                onPressed: _jumpToNewest,
              ),
            ),
          ),
      ],
    );
  }

  /// The messages oldest first, with a date between days and a divider before the first unread.
  List<Widget> _rows(BuildContext context, ChatThreadState data) {
    final l10n = AppLocalizations.of(context);
    final thread = data.thread;
    final rows = <Widget>[];
    DateTime? previousDay;
    for (final message in data.messages) {
      if (previousDay == null || !sameDay(previousDay, message.createdAt)) {
        rows.add(_DateSeparator(date: message.createdAt));
        previousDay = message.createdAt;
      }
      if (data.firstUnreadSeq > 0 && message.seq == data.firstUnreadSeq) {
        rows.add(_NewDivider(key: _unreadKey, label: l10n.chatNewMessages));
      }
      rows.add(
        message.type.isCard
            ? SystemCard(
                key: ValueKey('card-${message.seq}-${message.clientMessageId}'),
                message: message,
                onOpenListing: () => context.push(RouteNames.listingView(thread.listing.listingId)),
              )
            : MessageBubble(
                key: ValueKey('${message.seq}-${message.clientMessageId}'),
                message: message,
                counterpartName: thread.counterpart.displayName,
                onRetry: () => unawaited(_controller.retry(message.clientMessageId)),
                onDiscard: () => _controller.discard(message.clientMessageId),
              ),
      );
    }
    return rows;
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Text(
          MaterialLocalizations.of(context).formatMediumDate(date),
          style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
        ),
      ),
    );
  }
}

/// "Name is typing…" above the composer; announced politely when it appears.
class _TypingIndicator extends StatelessWidget {
  final String name;

  const _TypingIndicator({required this.name});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).chatTyping(name);
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AppColors.brandMutedText),
        ),
      ),
    );
  }
}

class _NewDivider extends StatelessWidget {
  final String label;

  const _NewDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.brandLink)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.brandLink)),
            ),
            const Expanded(child: Divider(color: AppColors.brandLink)),
          ],
        ),
      ),
    );
  }
}

class _OlderLoader extends StatelessWidget {
  final bool loading;
  final Future<void> Function() onLoad;

  const _OlderLoader({required this.loading, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(
                onPressed: onLoad,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(l10n.chatLoadOlder),
              ),
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  final String message;

  const _ReadOnlyBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brandSurface,
        border: Border(top: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandMutedText),
            ),
          ),
        ),
      ),
    );
  }
}
