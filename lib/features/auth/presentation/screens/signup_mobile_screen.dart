import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/mobile_number_field.dart';

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
        SnackBar(
          content: Text(AppLocalizations.of(context).signupMobileOtpComingSoon),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
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
                      Text(
                        l10n.signupMobileTitle,
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.signupMobileSubtitle,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(l10n.signupMobileLabel, style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      MobileNumberField(
                        onChanged: (value) => setState(() => _mobile = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: AppColors.brandPlaceholder,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.signupMobileHint,
                            style: AppTextStyles.hint,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BrandGradientButton(
                label: l10n.signupMobileSendOtp,
                onPressed: _isValid ? _sendOtp : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
