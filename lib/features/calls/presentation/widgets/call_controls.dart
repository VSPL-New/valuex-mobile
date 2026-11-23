import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// How a round call control looks.
enum CallControlStyle {
  /// A dark translucent disc over the call background.
  normal,

  /// The same, lit: the control is on (muted, speaker).
  active,

  /// Red: End, Decline.
  danger,

  /// Green: Accept.
  accept,
}

/// A round control with a label under it, at least 56 dp wide (the target is larger than the
/// 48 dp minimum). The label is spoken as the control's name, and the lit state is announced.
class CallControl extends StatelessWidget {
  static const double size = 60;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final CallControlStyle style;

  const CallControl({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.style = CallControlStyle.normal,
  });

  Color get _fill => switch (style) {
        CallControlStyle.normal => Colors.black.withValues(alpha: 0.32),
        CallControlStyle.active => AppColors.brandSurface,
        CallControlStyle.danger => AppColors.brandError,
        CallControlStyle.accept => AppColors.brandSuccess,
      };

  Color get _icon =>
      style == CallControlStyle.active ? AppColors.brandForeground : AppColors.brandOnPrimary;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      toggled: style == CallControlStyle.active ? true : null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: size + AppSpacing.md),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          // The whole control, label included, is the tap target.
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: _fill, shape: BoxShape.circle),
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: Icon(icon, color: _icon, size: 26),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandOnPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A banner over the call: a warning or a weak line, with an optional action.
class CallBanner extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CallBanner({super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.brandForeground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(actionLabel!, style: AppTextStyles.linkSmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small pill on the call background (the connection quality, "not recorded").
class CallChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const CallChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.brandOnPrimary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.brandOnPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
