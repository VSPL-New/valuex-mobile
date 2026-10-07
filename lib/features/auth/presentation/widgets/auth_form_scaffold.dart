import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/square_back_button.dart';

/// Page frame shared by the registration steps: back button, logo, title and
/// subtitle, scrollable form content and a fixed action area at the bottom.
class AuthFormScaffold extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final List<Widget> content;
  final Widget bottom;

  const AuthFormScaffold({
    super.key,
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.bottom,
  });

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
                      SquareBackButton(onPressed: onBack),
                      const SizedBox(height: AppSpacing.lg),
                      const BrandLogo(height: 32),
                      const SizedBox(height: AppSpacing.xl),
                      Semantics(header: true, child: Text(title, style: AppTextStyles.heading2)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(subtitle, style: AppTextStyles.bodySecondary),
                      const SizedBox(height: AppSpacing.xl),
                      ...content,
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
