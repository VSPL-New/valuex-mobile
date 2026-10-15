import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand_bottom_nav.dart';
import '../../../core/widgets/field_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../domain/entities/home_badges.dart';
import '../domain/entities/listing.dart';
import 'main_nav.dart';
import 'providers/home_providers.dart';
import 'widgets/category_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/listing_card.dart';
import 'widgets/location_prompt.dart';
import 'widgets/location_sheet.dart';
import 'widgets/promo_carousel.dart';
import 'widgets/saved_location_dialog.dart';
import 'widgets/section_header.dart';

/// Home: location, search, promo, categories and featured deals near the user.
/// Screens that are not built yet answer with a passing "coming soon" message.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(promosProvider)
      ..invalidate(categoriesProvider)
      ..invalidate(homeBadgesProvider)
      ..invalidate(unreadNotificationsProvider)
      ..invalidate(featuredListingsProvider);
    try {
      await ref.read(featuredListingsProvider.future);
    } on Object {
      // The error is shown in the list itself.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locationAsync = ref.watch(homeLocationControllerProvider);
    final location = locationAsync.value;
    final cart = ref.watch(homeBadgesProvider).value ?? const HomeBadges();
    final badges = HomeBadges(
      cartItems: cart.cartItems,
      unreadNotifications: ref.watch(unreadNotificationsProvider).value ?? 0,
    );
    final promos = ref.watch(promosProvider).value ?? const [];
    final categories = ref.watch(categoriesProvider);
    final listings = ref.watch(featuredListingsProvider);
    final controller = ref.read(homeLocationControllerProvider.notifier);

    final known = location is LocationKnown ? location.location : null;
    final needed = location is LocationNeeded ? location : null;

    return Scaffold(
      bottomNavigationBar: BrandBottomNav(
        current: BottomNavItem.home,
        chatsHasUnread: true,
        onSelected: (item) =>
            onMainNavSelected(context, ref, current: BottomNavItem.home, item: item),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                placeTitle: known?.title,
                placeSubtitle: known?.subtitle,
                locating: locationAsync.isLoading,
                badges: badges,
                onLocation: () => showLocationSheet(context),
                onCart: () => showComingSoon(context),
                onNotifications: () => context.push(RouteNames.notifications),
                onSearch: () => showComingSoon(context),
                onPhotoSearch: () => showComingSoon(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (needed != null) ...[
                    LocationPrompt(
                      need: needed.reason,
                      onUseLocation: controller.useDeviceLocation,
                      onOpenSettings: controller.openSettings,
                      onUseSaved: () => showSavedLocationDialog(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  PromoCarousel(
                    promos: promos,
                    onPromoTap: (_) => showComingSoon(context),
                    onSeeAll: () => showComingSoon(context),
                  ),
                  if (promos.isNotEmpty) const SizedBox(height: AppSpacing.md),
                  SectionHeader(title: l10n.homeBrowse),
                  categories.when(
                    data: (items) => CategoryRow(
                      categories: items,
                      onSelect: (_) => showComingSoon(context),
                      onMore: () => context.push(RouteNames.categories),
                    ),
                    loading: () => const _Skeleton(height: 72),
                    error: (error, stack) => _SectionError(
                      message: l10n.homeCategoriesFailed,
                      onRetry: () => ref.invalidate(categoriesProvider),
                    ),
                  ),
                  if (needed == null) ...[
                    const SizedBox(height: AppSpacing.md),
                    SectionHeader(
                      title: l10n.homeFeaturedTitle,
                      actionLabel: known != null && (listings.value?.isNotEmpty ?? false)
                          ? l10n.homeSeeAll
                          : null,
                      onAction: () => showComingSoon(context),
                    ),
                  ],
                ]),
              ),
            ),
            ..._featured(context, ref, location, locationAsync.isLoading, listings),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }

  List<Widget> _featured(
    BuildContext context,
    WidgetRef ref,
    HomeLocationState? location,
    bool locating,
    AsyncValue<List<Listing>> listings,
  ) {
    final l10n = AppLocalizations.of(context);
    const sidePadding = EdgeInsets.symmetric(horizontal: AppSpacing.md);

    Widget box(Widget child) => SliverPadding(
          padding: sidePadding,
          sliver: SliverToBoxAdapter(child: child),
        );

    if (locating || location == null) return [box(const _Skeleton(height: 240))];

    // The prompt at the top of the page replaces the listings until a place is known.
    if (location is LocationNeeded) return const [];

    final items = listings.value;
    if (items == null) {
      if (listings.hasError) {
        return [
          box(
            _SectionError(
              message: l10n.homeLoadFailed,
              onRetry: () => ref.invalidate(featuredListingsProvider),
            ),
          ),
        ];
      }
      return [box(const _Skeleton(height: 240))];
    }

    if (items.isEmpty) {
      return [box(Text(l10n.homeNoListings, style: AppTextStyles.hint))];
    }

    return [
      if (listings.hasError)
        box(
          _SectionError(
            message: l10n.homeLoadFailed,
            onRetry: () => ref.invalidate(featuredListingsProvider),
          ),
        ),
      SliverPadding(
        padding: sidePadding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: (items.length + 1) ~/ 2,
            (context, row) {
              final first = items[row * 2];
              final second = row * 2 + 1 < items.length ? items[row * 2 + 1] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          child: ListingCard(listing: first, onTap: () => showComingSoon(context))),
                      const SizedBox(width: AppSpacing.md - 4),
                      Expanded(
                        child: second == null
                            ? const SizedBox.shrink()
                            : ListingCard(listing: second, onTap: () => showComingSoon(context)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldError(text: message),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: AppLocalizations.of(context).commonRetry,
          onPressed: onRetry,
          isOutlined: true,
        ),
      ],
    );
  }
}

/// Grey placeholder while content loads; static when the system asks for reduced motion.
class _Skeleton extends StatelessWidget {
  final double height;

  const _Skeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    final block = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: SizedBox(height: height, width: double.infinity),
    );
    return Semantics(
      label: AppLocalizations.of(context).loading,
      liveRegion: true,
      excludeSemantics: true,
      child: MediaQuery.disableAnimationsOf(context)
          ? block
          : Shimmer.fromColors(
              baseColor: AppColors.brandMuted,
              highlightColor: AppColors.brandSurface,
              child: block,
            ),
    );
  }
}
