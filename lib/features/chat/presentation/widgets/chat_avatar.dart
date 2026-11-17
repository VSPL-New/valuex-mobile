import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/text_styles.dart';

/// The other person's initial on the brand gradient: a rounded square in the list, a circle in the
/// conversation header. Decorative, so it is left out of the reading order.
class ChatAvatar extends StatelessWidget {
  final String initial;
  final double size;
  final bool circle;

  const ChatAvatar({super.key, required this.initial, this.size = 56, this.circle = false});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(size * 0.28),
        ),
        // The size is fixed, so the initial does not grow with the text scale.
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: Text(
            initial,
            style: AppTextStyles.heading2
                .copyWith(color: AppColors.brandOnPrimary, fontSize: size * 0.36),
          ),
        ),
      ),
    );
  }
}
