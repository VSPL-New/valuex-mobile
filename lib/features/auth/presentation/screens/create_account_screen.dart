import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/outlined_icon_button.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/labeled_divider.dart';

/// Landing page after onboarding: choose how to register or sign in
/// (Figma: Create account).
class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Design leaves 54px below the last button (includes the home indicator).
    final bottomPadding = math.max(54.0, bottomInset + 24);

    return Scaffold(
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
                    label: l10n.createAccountCreate,
                    onPressed: () => context.go(RouteNames.signupMobile),
                  ),
                  const SizedBox(height: 11),
                  SingleToneButton(
                    label: l10n.createAccountSignIn,
                    onPressed: () => context.go(RouteNames.signIn),
                  ),
                  const SizedBox(height: 25),
                  LabeledDivider(label: l10n.createAccountOrLoginWith),
                  const SizedBox(height: 30),
                  OutlinedIconButton(
                    label: l10n.createAccountContinueGoogle,
                    iconAsset: AppAssets.googleIcon,
                    onPressed: () => _comingSoon(context, l10n.createAccountGoogleComingSoon),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedIconButton(
                    label: l10n.createAccountContinueGuest,
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
              // The PNG has an opaque white backdrop; multiply blends it into the page colour.
              color: AppColors.brandBackground,
              colorBlendMode: BlendMode.multiply,
            ),
          ),
          const Positioned(
            left: 163,
            top: 204,
            width: 57,
            height: 22,
            child: BrandLogo(fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
