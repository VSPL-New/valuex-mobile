import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Square back/next control used on the onboarding slides.
class OnboardingNavButton extends StatelessWidget {
  final Color backgroundColor;
  final double radius;
  final bool pointsBack;
  final VoidCallback onPressed;

  const OnboardingNavButton({
    super.key,
    required this.backgroundColor,
    required this.onPressed,
    this.radius = 7,
    this.pointsBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
                'assets/icons/arrow_right.svg',
                width: 18,
                height: 12.41,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
