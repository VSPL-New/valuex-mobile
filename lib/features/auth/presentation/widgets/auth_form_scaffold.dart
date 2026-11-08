import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/square_back_button.dart';

/// Page frame shared by the registration steps: back button, title and
/// subtitle, scrollable form content and a fixed action area at the bottom.
class AuthFormScaffold extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final List<Widget> content;
  final Widget bottom;

  /// Puts the title and subtitle, centred, on the same level as the back button.
  final bool centeredHeader;

  /// Control shown at the right of the back button (the language chip on Sign In).
  final Widget? trailing;

  const AuthFormScaffold({
    super.key,
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.bottom,
    this.centeredHeader = false,
    this.trailing,
  });

  Widget _header() {
    final heading = Semantics(header: true, child: Text(title, style: AppTextStyles.heading2));
    if (!centeredHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [SquareBackButton(onPressed: onBack), if (trailing != null) trailing!],
          ),
          const SizedBox(height: AppSpacing.lg),
          heading,
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTextStyles.bodySecondary),
        ],
      );
    }
    return Stack(
      children: [
        // Side padding keeps long or large text clear of the back button.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.minTouchTarget + AppSpacing.sm),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                heading,
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        Align(alignment: Alignment.topLeft, child: SquareBackButton(onPressed: onBack)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: AppSpacing.xl),
                      ...content,
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              bottom,
            ],
          ),
        ),
      ),
    );
  }
}
