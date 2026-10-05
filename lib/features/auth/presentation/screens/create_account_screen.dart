import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/brand_gradient_button.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/outlined_icon_button.dart';
import '../../../shared/widgets/single_tone_button.dart';
import '../../../shared/widgets/square_back_button.dart';
import 'widgets/labeled_divider.dart';

/// Landing page after onboarding: choose how to register or sign in
/// (Figma: Create account).
class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Design leaves 54px below the last button (includes the home indicator).
    final bottomPadding = math.max(54.0, bottomInset + 24);

    return Scaffold(
      backgroundColor: AppColors.brandSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 21.5, top: 22.6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SquareBackButton(
                  onPressed: () => context.go(RouteNames.onboarding),
                ),
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 28, 22, 31),
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: _Hero()),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(21.5, 0, 21.5, bottomPadding),
              child: Column(
                children: [
                  BrandGradientButton(
                    label: 'Create an Account',
                    onPressed: () => context.go(RouteNames.signupMobile),
                  ),
                  const SizedBox(height: 11),
                  SingleToneButton(
                    label: 'Sign In',
                    onPressed: () => _comingSoon(context, 'Sign in'),
                  ),
                  const SizedBox(height: 25),
                  const LabeledDivider(label: 'Or login with'),
                  const SizedBox(height: 30),
                  OutlinedIconButton(
                    label: 'Continue with Google',
                    iconAsset: AppAssets.googleIcon,
                    onPressed: () => _comingSoon(context, 'Google sign-in'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedIconButton(
                    label: 'Continue as Guest',
                    iconAsset: AppAssets.guestIcon,
                    onPressed: () => context.go(RouteNames.home),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 384x384 illustration with the brand mark placed on the phone screen.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 384,
      height: 384,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.createAccountIllustration,
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(
            left: 163,
            top: 204,
            width: 57,
            height: 22,
            // The phone screen in the illustration is white.
            child: BrandLogo(fit: BoxFit.cover, blendWith: null),
          ),
        ],
      ),
    );
  }
}
