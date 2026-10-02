import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// 3-dot page indicator. The active dot is elongated; on the final page
/// (per Figma) all dots switch to the active color to signal the flow end.
class OnboardingDots extends StatelessWidget {
  final int activeDot;
  final bool highlightAll;

  const OnboardingDots({
    super.key,
    required this.activeDot,
    this.highlightAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index == activeDot;
        final color = (isActive || highlightAll)
            ? AppColors.onboardingDotActive
            : AppColors.onboardingDotInactive;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 33 : 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}
