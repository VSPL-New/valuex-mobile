import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_bottom_nav.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/entities/logout_outcome.dart';
import '../../auth/presentation/auth_error_messages.dart';
import '../../home/presentation/main_nav.dart';
import '../data/mock_profile_summary.dart';
import '../data/profile_repository.dart';
import 'providers/logout_action.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_section.dart';

/// Profile tab: who the user is, then shortcuts to buying, selling and account screens.
/// Screens that are not built yet answer with a passing "coming soon" message.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Confirms, then logs out. The page is gone once the session ends, so nothing here touches
  /// `ref` or `context` after the logout call.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final logout = ref.read(logoutActionProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.profileSignOut),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.brandError),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.profileSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: LoadingIndicator()),
    ));
    final outcome = await logout();
    navigator.pop();
    if (outcome == LogoutOutcome.queued) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.logoutQueued)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loaded = ref.watch(userProfileProvider);
    final profile = loaded.value;
    final summary = ref.watch(profileSummaryProvider);

    ProfileMenuItem item(IconData icon, String label) =>
        ProfileMenuItem(icon: icon, label: label, onTap: () => showComingSoon(context));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(RouteNames.home);
      },
      child: Scaffold(
        bottomNavigationBar: BrandBottomNav(
          current: BottomNavItem.profile,
          onSelected: (next) =>
              onMainNavSelected(context, ref, current: BottomNavItem.profile, item: next),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHero(
                child: profile != null
                    ? ProfileHeader(
                        profile: profile,
                        summary: summary,
                        onEdit: () => context.push(RouteNames.profileDetails),
                        onUpgrade: () => showComingSoon(context),
                      )
                    : loaded.hasError
                        ? ErrorView(
                            message: authErrorMessage(l10n, loaded.error!),
                            onRetry: () => ref.invalidate(userProfileProvider),
                          )
                        : const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: LoadingIndicator(),
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileMenuSection(
                      title: l10n.profileSectionBuying,
                      items: [
                        item(Icons.inventory_2_outlined, l10n.profileMyOrders),
                        item(Icons.favorite_border, l10n.profileSavedItems),
                        item(Icons.credit_card, l10n.profilePaymentHistory),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileMenuSection(
                      title: l10n.profileSectionSelling,
                      items: [
                        item(Icons.assignment_outlined, l10n.profileIncomingOrders),
                        item(Icons.sell_outlined, l10n.profileMyListings),
                        item(Icons.account_balance_outlined, l10n.profilePayoutDetails),
                        item(Icons.bar_chart, l10n.profileSellerAnalytics),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileMenuSection(
                      title: l10n.profileSectionAccount,
                      items: [
                        item(Icons.notifications_none, l10n.profileNotifications),
                        item(Icons.language, l10n.profileLanguage),
                        item(Icons.shield_outlined, l10n.profileDisputeCenter),
                        item(Icons.help_outline, l10n.profileHelpSupport),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileSignOutTile(
                      label: l10n.profileSignOut,
                      onTap: () => _signOut(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.profileFooter(AppConstants.appVersion),
                      style: AppTextStyles.hint,
                      textAlign: TextAlign.center,
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
