import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// A rounded square holding one icon: a soft blue tile by default, or [gradient] with a white
/// icon. Purely decorative, so it is hidden from screen readers.
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient? gradient;

  const IconTile({super.key, required this.icon, this.size = 44, this.gradient});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppColors.brandPrimary.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: gradient == null ? AppColors.brandPrimary : AppColors.brandOnPrimary,
          ),
        ),
      ),
    );
  }
}

/// White card with the faint edge and soft shadow used by the plan, photo and details pages.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.xl,
  });

  static BoxDecoration decoration([double radius = AppRadius.xl]) => BoxDecoration(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.brandBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x14135CFF), blurRadius: 10, offset: Offset(0, 2)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: decoration(radius), child: Padding(padding: padding, child: child));
  }
}
