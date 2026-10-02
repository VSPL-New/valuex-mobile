import 'package:flutter/material.dart';

/// Circular back/next control used on the onboarding slides.
class OnboardingNavButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const OnboardingNavButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 45,
          height: 45,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
