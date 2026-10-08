import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Error message under a field: an icon and text (never colour alone), announced as soon as it
/// appears.
class FieldError extends StatelessWidget {
  final String text;

  const FieldError({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline_rounded, size: 18, color: AppColors.brandError),
          ),
          const SizedBox(width: AppSpacing.sm - 2),
          Expanded(child: Text(text, style: AppTextStyles.error)),
        ],
      ),
    );
  }
}
