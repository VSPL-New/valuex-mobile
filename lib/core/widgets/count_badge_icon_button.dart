import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Round translucent icon button for use on the brand gradient. A dot shows when [showDot] is
/// true; the screen reader hears [label], which should carry the count.
class CountBadgeIconButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool showDot;
  final VoidCallback onPressed;

  const CountBadgeIconButton({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.onPressed,
    this.showDot = false,
  });

  static const double _visual = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: AppSizes.minTouchTarget,
          height: AppSizes.minTouchTarget,
          child: Center(
            child: SizedBox(
              width: _visual,
              height: _visual,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandOnPrimary.withValues(alpha: 0.15),
                    ),
                    child: Center(child: SvgPicture.asset(iconAsset, width: 20, height: 20)),
                  ),
                  if (showDot)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandOnPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
