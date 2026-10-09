import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_assets.dart';
import '../theme/colors.dart';
import '../theme/gradients.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

enum BottomNavItem { home, search, sell, chats, profile }

/// Main navigation: four tabs around a raised Sell button. Every item has a 48 dp tap area
/// and is announced with its label and whether it is the current one.
class BrandBottomNav extends StatelessWidget {
  final BottomNavItem current;
  final bool chatsHasUnread;
  final ValueChanged<BottomNavItem> onSelected;

  const BrandBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
    this.chatsHasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget tab(BottomNavItem item, String label, String icon, {bool dot = false}) {
      return Expanded(
        child: _NavTab(
          label: label,
          iconAsset: icon,
          selected: current == item,
          showDot: dot,
          onTap: () => onSelected(item),
        ),
      );
    }

    // Five tabs share the width, so their labels grow up to 1.4x; each tab is still announced
    // by its full label.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.brandSurface,
          border: Border(top: BorderSide(color: AppColors.brandBorder)),
          boxShadow: [BoxShadow(color: Color(0x0F2D6BFF), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Row(
              children: [
                tab(BottomNavItem.home, l10n.navHome, AppAssets.navHomeIcon),
                tab(BottomNavItem.search, l10n.navSearch, AppAssets.navSearchIcon),
                Expanded(
                  child: _SellTab(label: l10n.navSell, onTap: () => onSelected(BottomNavItem.sell)),
                ),
                tab(
                  BottomNavItem.chats,
                  l10n.navChats,
                  AppAssets.navChatsIcon,
                  dot: chatsHasUnread,
                ),
                tab(BottomNavItem.profile, l10n.navProfile, AppAssets.navProfileIcon),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _NavTab({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brandLink : AppColors.brandMutedText;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    iconAsset,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  if (showDot)
                    const Positioned(
                      top: -2,
                      right: -4,
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              // The current tab is shown by this bar as well as by colour.
              SizedBox(
                width: 16,
                height: 2,
                child: selected
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellTab extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SellTab({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only the button is announced; the visible label repeats its name.
          Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            onTap: onTap,
            child: Container(
              width: AppSizes.minTouchTarget,
              height: AppSizes.minTouchTarget,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border:
                    Border.all(color: AppColors.brandOnPrimary.withValues(alpha: 0.3), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x662D6BFF), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Center(child: SvgPicture.asset(AppAssets.navSellIcon, width: 22, height: 22)),
            ),
          ),
          const SizedBox(height: 2),
          ExcludeSemantics(
            child: Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}
