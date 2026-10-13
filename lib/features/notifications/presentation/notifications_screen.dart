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
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_error_messages.dart';
import '../../home/presentation/main_nav.dart';
import '../../profile/presentation/widgets/profile_menu_section.dart';
import '../domain/app_notification.dart';
import '../domain/notification_deep_links.dart';
import 'providers/notifications_providers.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_tabs.dart';

/// Notification history, newest first. Tapping one marks it read and opens its screen.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const double _loadMoreDistance = 300;

  final ScrollController _scroll = ScrollController();

  /// Null shows every notification.
  NotificationCategory? _category;

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

  NotificationsController get _controller => ref.read(notificationsControllerProvider.notifier);

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < _loadMoreDistance) {
      unawaited(_controller.loadMore());
    }
  }

  /// A filtered or short list may not fill the screen, so no scroll would ever ask for more.
  void _fillScreen(NotificationsState state) {
    if (!state.hasMore || state.loadingMore || state.loadMoreFailed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients && _scroll.position.extentAfter < _loadMoreDistance) {
        unawaited(_controller.loadMore());
      }
    });
  }

  Future<void> _markAllRead() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).notificationsMarkAllFailed;
    try {
      await _controller.markAllRead();
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _open(AppNotification notification) {
    unawaited(_controller.markRead(notification.id));
    final target = notificationTargetFor(notification.deepLink);
    if (target == null) {
      if (notification.deepLink != null) showComingSoon(context);
      return;
    }
    if (target.isTab) {
      context.go(target.route);
    } else {
      unawaited(context.push(target.route));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(notificationsControllerProvider);
    final state = async.value;
    final unread = ref.watch(unreadNotificationsProvider).value ??
        state?.items.where((n) => !n.read).length ??
        0;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            unread: unread,
            showMarkAll: unread > 0 && state != null,
            markingAll: state?.markingAll ?? false,
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
            onMarkAll: _markAllRead,
          ),
          Expanded(
            child: state != null
                ? _content(l10n, state)
                : async.hasError
                    ? ErrorView(
                        message: authErrorMessage(l10n, async.error!),
                        onRetry: () => ref.invalidate(notificationsControllerProvider),
                      )
                    : const LoadingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _content(AppLocalizations l10n, NotificationsState state) {
    final categories = [
      for (final category in NotificationCategory.values)
        if (state.items.any((n) => n.category == category)) category,
    ];
    final selected = categories.contains(_category) ? _category : null;
    final shown = selected == null
        ? state.items
        : [
            for (final item in state.items)
              if (item.category == selected) item
          ];
    _fillScreen(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // With a single category the All tab would show the same list.
        if (categories.length > 1)
          NotificationTabs(
            categories: categories,
            selected: selected,
            onSelected: (category) => setState(() => _category = category),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: shown.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _Empty(title: l10n.notificationsEmptyTitle, body: l10n.notificationsEmptyBody)
                    ],
                  )
                : ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: shown.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == shown.length) {
                        return _Footer(state: state, onRetry: _controller.loadMore);
                      }
                      final notification = shown[index];
                      return NotificationCard(
                        key: ValueKey(notification.id),
                        notification: notification,
                        onTap: () => _open(notification),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int unread;
  final bool showMarkAll;
  final bool markingAll;
  final VoidCallback onBack;
  final VoidCallback onMarkAll;

  const _Header({
    required this.unread,
    required this.showMarkAll,
    required this.markingAll,
    required this.onBack,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.brandSurface, boxShadow: profileCardShadow),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SquareBackButton(onPressed: onBack),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(l10n.notificationsTitle, style: AppTextStyles.heading2),
                        ),
                        Text(l10n.notificationsUnreadCount(unread), style: AppTextStyles.hint),
                      ],
                    ),
                  ),
                  if (showMarkAll)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                        foregroundColor: AppColors.brandLink,
                        textStyle: AppTextStyles.linkSmall,
                      ),
                      onPressed: markingAll ? null : onMarkAll,
                      child: Text(l10n.notificationsMarkAllRead),
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

class _Empty extends StatelessWidget {
  final String title;
  final String body;

  const _Empty({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const ExcludeSemantics(
            child: Icon(Icons.notifications_none, size: 48, color: AppColors.brandMutedText),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.sectionTitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTextStyles.hint, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Spinner while the next page loads, or a retry line when it failed.
class _Footer extends StatelessWidget {
  final NotificationsState state;
  final Future<void> Function() onRetry;

  const _Footer({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.loadingMore) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LoadingIndicator());
    }
    if (state.loadMoreFailed) {
      return Column(
        children: [
          Text(l10n.notificationsLoadMoreFailed,
              style: AppTextStyles.error, textAlign: TextAlign.center),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
              foregroundColor: AppColors.brandLink,
              textStyle: AppTextStyles.linkSmall,
            ),
            onPressed: onRetry,
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
