import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/motion.dart';
import '../../../../l10n/app_localizations.dart';

/// Page indicator with one dot per onboarding page; the active dot is elongated.
class OnboardingDots extends StatelessWidget {
  final int count;
  final int activeDot;

  const OnboardingDots({
    super.key,
    required this.count,
    required this.activeDot,
  });

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == activeDot;
        final color = isActive ? AppColors.onboardingDotActive : AppColors.onboardingDotInactive;
        return AnimatedContainer(
          duration: motionDuration(context, const Duration(milliseconds: 200)),
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
    return Semantics(
      label: AppLocalizations.of(context).onboardingPageOf(activeDot + 1, count),
      excludeSemantics: true,
      child: dots,
    );
  }
}
