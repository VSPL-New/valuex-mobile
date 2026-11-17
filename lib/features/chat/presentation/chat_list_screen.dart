import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_bottom_nav.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/main_nav.dart';
import '../domain/chat.dart';
import 'providers/chat_list_controller.dart';
import 'providers/chat_unread_provider.dart';
import 'widgets/chat_list_tile.dart';

/// The Chats tab (US-013): every conversation of the signed-in user, newest activity first, with
/// a search on the names and listing titles that are loaded and a Buying and Selling filter.
/// Message text is never searched.
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ChatThread> _matching(List<ChatThread> threads) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return threads;
    return [
      for (final thread in threads)
        if (thread.counterpart.displayName.toLowerCase().contains(query) ||
            thread.listing.title.toLowerCase().contains(query))
          thread,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(chatRoleFilterProvider);
    final list = ref.watch(chatListControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      bottomNavigationBar: BrandBottomNav(
        current: BottomNavItem.chats,
        chatsHasUnread: ref.watch(chatsHasUnreadProvider),
        onSelected: (item) =>
            onMainNavSelected(context, ref, current: BottomNavItem.chats, item: item),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Semantics(
                  header: true, child: Text(l10n.chatsTitle, style: AppTextStyles.heading1)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _search,
                style: AppTextStyles.input,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.chatsSearchHint,
                  hintStyle: AppTextStyles.hint,
                  semanticCounterText: '',
                  filled: true,
                  fillColor: AppColors.brandSurface,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brandMutedText),
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  border: _border(AppColors.brandBorder),
                  enabledBorder: _border(AppColors.brandBorder),
                  focusedBorder: _border(AppColors.brandBorderFocused, width: 2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final (value, label) in [
                    (ChatRole.all, l10n.chatsFilterAll),
                    (ChatRole.buying, l10n.chatsFilterBuying),
                    (ChatRole.selling, l10n.chatsFilterSelling),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: role == value,
                      onSelected: (_) => ref.read(chatRoleFilterProvider.notifier).select(value),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.brandBorder),
            Expanded(
              child: list.when(
                loading: () => const Center(child: LoadingIndicator()),
                error: (error, stack) => ErrorView(
                  message: l10n.chatsLoadFailed,
                  onRetry: () => ref.invalidate(chatListControllerProvider),
                ),
                data: (data) => _list(context, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl + 8),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _list(BuildContext context, ChatListState data) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final threads = _matching(data.threads);
    Future<void> refresh() async {
      try {
        await ref.read(chatListControllerProvider.notifier).refresh();
        ref.invalidate(chatUnreadCountProvider);
      } on Object {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.chatsLoadFailed)));
      }
    }

    if (threads.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              searching ? l10n.chatsNoResults : l10n.chatsEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.brandForeground),
            ),
            if (!searching) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.chatsEmptyHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandMutedText),
              ),
            ],
          ],
        ),
      );
    }
    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: threads.length + (data.hasNext ? 1 : 0),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.brandBorder),
        itemBuilder: (context, index) {
          if (index == threads.length) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: data.loadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : TextButton(
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: () async {
                          final ok = await ref.read(chatListControllerProvider.notifier).loadMore();
                          if (!ok) {
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(l10n.chatsLoadMoreFailed)));
                          }
                        },
                        child: Text(l10n.chatLoadOlder),
                      ),
              ),
            );
          }
          final thread = threads[index];
          return ChatListTile(
            thread: thread,
            now: now,
            onTap: () async {
              await context.push(RouteNames.chatThread(thread.threadId));
              if (mounted) ref.invalidate(chatListControllerProvider);
            },
          );
        },
      ),
    );
  }
}
