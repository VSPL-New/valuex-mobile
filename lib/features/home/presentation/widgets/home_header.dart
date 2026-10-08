import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/count_badge_icon_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/home_badges.dart';

/// Gradient header: where I am, cart, notifications and the search bar.
class HomeHeader extends StatelessWidget {
  /// First and second line of the place; null while it is unknown.
  final String? placeTitle;
  final String? placeSubtitle;
  final bool locating;
  final HomeBadges badges;
  final VoidCallback onLocation;
  final VoidCallback onCart;
  final VoidCallback onNotifications;
  final VoidCallback onSearch;
  final VoidCallback onPhotoSearch;

  const HomeHeader({
    super.key,
    required this.placeTitle,
    required this.placeSubtitle,
    required this.locating,
    required this.badges,
    required this.onLocation,
    required this.onCart,
    required this.onNotifications,
    required this.onSearch,
    required this.onPhotoSearch,
  });

  static const double _bottomRadius = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(_bottomRadius)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _LocationButton(
                      title: locating ? l10n.homeLocating : placeTitle ?? l10n.homeSetLocation,
                      subtitle: locating ? null : placeSubtitle ?? l10n.homeSetLocationHint,
                      onTap: onLocation,
                    ),
                  ),
                  CountBadgeIconButton(
                    iconAsset: AppAssets.homeCartIcon,
                    label: l10n.homeCartLabel(badges.cartItems),
                    showDot: badges.cartItems > 0,
                    onPressed: onCart,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CountBadgeIconButton(
                    iconAsset: AppAssets.homeBellIcon,
                    label: l10n.homeNotificationsLabel(badges.unreadNotifications),
                    showDot: badges.unreadNotifications > 0,
                    onPressed: onNotifications,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SearchBar(onSearch: onSearch, onPhotoSearch: onPhotoSearch),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _LocationButton({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitle = this.subtitle;
    return Semantics(
      button: true,
      label: l10n.homeLocationLabel([title, if (subtitle != null) subtitle].join(', ')),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  SvgPicture.asset(AppAssets.homeLocationPinIcon, width: 16, height: 16),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.onGradientStrong,
                    ),
                  ),
                  const SizedBox(width: 2),
                  SvgPicture.asset(AppAssets.homeChevronDownIcon, width: 12, height: 12),
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.onGradient,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onPhotoSearch;

  const _SearchBar({required this.onSearch, required this.onPhotoSearch});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: AppColors.brandSurface,
      borderRadius: radius,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.homeSearchLabel,
              excludeSemantics: true,
              onTap: onSearch,
              child: InkWell(
                onTap: onSearch,
                borderRadius: radius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md - 2),
                    child: Row(
                      children: [
                        SvgPicture.asset(AppAssets.homeSearchIcon, width: 16, height: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.homeSearchHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.input.copyWith(color: AppColors.brandPlaceholder),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.homePhotoSearchLabel,
            excludeSemantics: true,
            onTap: onPhotoSearch,
            child: InkWell(
              onTap: onPhotoSearch,
              borderRadius: radius,
              child: SizedBox(
                width: AppSizes.minTouchTarget,
                height: AppSizes.minTouchTarget,
                child: Center(
                  child: SvgPicture.asset(AppAssets.homeCameraIcon, width: 20, height: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
