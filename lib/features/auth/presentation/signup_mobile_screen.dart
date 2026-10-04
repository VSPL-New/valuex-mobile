import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/brand_gradient_button.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/square_back_button.dart';
import 'widgets/mobile_number_field.dart';

/// Registration step 1: enter a mobile number to receive an OTP
/// (Figma Make: signup-phone "Create Account").
class SignupMobileScreen extends StatefulWidget {
  const SignupMobileScreen({super.key});

  @override
  State<SignupMobileScreen> createState() => _SignupMobileScreenState();
}

class _SignupMobileScreenState extends State<SignupMobileScreen> {
  static const _mobileLength = 10;

  String _mobile = '';

  bool get _isValid => _mobile.length == _mobileLength;

  void _sendOtp() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('OTP verification is coming soon')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SquareBackButton(
                        onPressed: () => context.go(RouteNames.createAccount),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const BrandLogo(height: 32),
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Create Account', style: AppTextStyles.heading2),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Join 10L+ users on JustQlic',
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text('MOBILE NUMBER', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      MobileNumberField(
                        onChanged: (value) => setState(() => _mobile = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: AppColors.brandPlaceholder,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "We'll send an OTP to verify your number",
                            style: AppTextStyles.hint,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BrandGradientButton(
                label: 'Send OTP',
                onPressed: _isValid ? _sendOtp : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
