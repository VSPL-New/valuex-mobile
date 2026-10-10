import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// Footer line that moves between sign up and sign in, e.g. "Already have an account? Sign In".
class AuthSwitchPrompt extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppTextStyles.bodySecondary),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          child: Text(actionLabel, style: AppTextStyles.link),
        ),
      ],
    );
  }
}
