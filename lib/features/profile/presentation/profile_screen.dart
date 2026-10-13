import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_bottom_nav.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_error_messages.dart';
import '../../home/presentation/main_nav.dart';
import '../data/mock_profile_summary.dart';
import '../data/profile_repository.dart';
import '../domain/profile_menu_badges.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_section.dart';

/// Profile tab: who the user is, then shortcuts to buying, selling and account screens.
/// Screens that are not built yet answer with a passing "coming soon" message.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(userProfileProvider)
      ..invalidate(profileMenuBadgesProvider);
    try {
      await Future.wait([
        ref.read(userProfileProvider.future),
        ref.read(profileMenuBadgesProvider.future),
      ]);
    } on Object {
      // A failed load is shown in place; the spinner just stops.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loaded = ref.watch(userProfileProvider);
    final profile = loaded.value;
    final summary = ref.watch(profileSummaryProvider);
    final badges = ref.watch(profileMenuBadgesProvider).value ?? const ProfileMenuBadges();

    ProfileMenuItem item(IconData icon, String label, [String? badgeKey]) => ProfileMenuItem(
          icon: icon,
          label: label,
          badge: badgeKey == null ? 0 : badges.count(badgeKey),
          onTap: () => showComingSoon(context),
        );

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
        body: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                          item(Icons.inventory_2_outlined, l10n.profileMyOrders,
                              ProfileMenuKeys.myOrders),
                          item(Icons.favorite_border, l10n.profileSavedItems,
                              ProfileMenuKeys.savedItems),
                          item(Icons.credit_card, l10n.profilePaymentHistory,
                              ProfileMenuKeys.transactions),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ProfileMenuSection(
                        title: l10n.profileSectionSelling,
                        items: [
                          item(Icons.assignment_outlined, l10n.profileIncomingOrders,
                              ProfileMenuKeys.incomingOrders),
                          item(Icons.sell_outlined, l10n.profileMyListings,
                              ProfileMenuKeys.myListings),
                          item(Icons.account_balance_outlined, l10n.profilePayoutDetails,
                              ProfileMenuKeys.payouts),
                          item(Icons.bar_chart, l10n.profileSellerAnalytics),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ProfileMenuSection(
                        title: l10n.profileSectionAccount,
                        items: [
                          item(Icons.notifications_none, l10n.profileNotifications,
                              ProfileMenuKeys.notifications),
                          item(Icons.language, l10n.profileLanguage),
                          item(Icons.shield_outlined, l10n.profileDisputeCenter,
                              ProfileMenuKeys.disputes),
                          item(Icons.help_outline, l10n.profileHelpSupport,
                              ProfileMenuKeys.supportTickets),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ProfileSignOutTile(
                        label: l10n.profileSignOut,
                        onTap: () => showComingSoon(context),
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
      ),
    );
  }
}
