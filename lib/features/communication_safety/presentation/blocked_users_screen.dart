import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/communication_safety.dart';
import 'providers/blocked_users_controller.dart';

/// Blocked users (US-132): the people the user blocked, newest first, each with Unblock.
class BlockedUsersScreen extends ConsumerStatefulWidget {
  /// Loads the next page when the list is this close to its end.
  static const double _loadMoreDistance = 240;

  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < BlockedUsersScreen._loadMoreDistance) _loadMore();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadMore() async {
    final failed = AppLocalizations.of(context).blockedUsersLoadMoreFailed;
    final ok = await ref.read(blockedUsersControllerProvider.notifier).loadMore();
    if (!ok && mounted) _show(failed);
  }

  Future<void> _unblock(BlockedUser user) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref.read(blockedUsersControllerProvider.notifier).unblock(user.userId);
    if (!mounted) return;
    _show(ok ? l10n.blockedUserUnblocked : l10n.blockedUserUnblockFailed);
  }

  Future<void> _refresh() async {
    ref.invalidate(blockedUsersControllerProvider);
    try {
      await ref.read(blockedUsersControllerProvider.future);
    } on Object {
      // The error is shown in place; the spinner just stops.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(blockedUsersControllerProvider);
    final blocked = async.value;

    final Widget body;
    if (blocked == null && async.hasError) {
      body = ErrorView(
        message: l10n.blockedUsersLoadFailed,
        onRetry: () => ref.invalidate(blockedUsersControllerProvider),
      );
    } else if (blocked == null) {
      body = const LoadingIndicator();
    } else if (blocked.items.isEmpty) {
      body = RefreshIndicator(onRefresh: _refresh, child: const _EmptyState());
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: blocked.items.length + (blocked.loadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= blocked.items.length) return const LoadingIndicator();
            final user = blocked.items[index];
            return _BlockedUserRow(user: user, onUnblock: () => _unblock(user));
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: SquareBackButton(
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go(RouteNames.profile),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.blockedUsersTitle, style: AppTextStyles.heading2),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.block, size: 48, color: AppColors.brandMutedText),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.blockedUsersEmpty,
                    style: AppTextStyles.body, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.blockedUsersEmptyHint,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedUserRow extends StatelessWidget {
  final BlockedUser user;
  final VoidCallback onUnblock;

  const _BlockedUserRow({required this.user, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SoftCard(
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.person_off_outlined, color: AppColors.brandMutedText),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(user.displayName, style: AppTextStyles.cardTitle, maxLines: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: l10n.blockedUserUnblockLabel(user.displayName),
            excludeSemantics: true,
            onTap: onUnblock,
            child: TextButton(
              onPressed: onUnblock,
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
              ),
              child: Text(l10n.blockedUserUnblock),
            ),
          ),
        ],
      ),
    );
  }
}
