import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/spacing.dart';

/// Square back/next control used on the onboarding slides.
class OnboardingNavButton extends StatelessWidget {
  final Color backgroundColor;
  final double radius;
  final bool pointsBack;
  final String label;
  final VoidCallback onPressed;

  const OnboardingNavButton({
    super.key,
    required this.backgroundColor,
    required this.onPressed,
    required this.label,
    this.radius = 7,
    this.pointsBack = false,
  });

  @override
  Widget build(BuildContext context) {
    // The 45 px square is the drawing; the tap area grows to the 48 dp minimum.
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
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onPressed,
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: pointsBack ? 2 : 0,
                      child: SvgPicture.asset(
                        AppAssets.arrowRightIcon,
                        width: 18,
                        height: 12.41,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
