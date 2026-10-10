import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_messages.dart';
import '../providers/entry_controllers.dart';
import '../widgets/auth_form_scaffold.dart';
import '../widgets/auth_switch_prompt.dart';
import '../widgets/mobile_number_field.dart';

/// Sign in step 1: enter the registered mobile number to receive an OTP
/// (Figma: Mobile No Sign In, built with the design system).
class SignInMobileScreen extends ConsumerStatefulWidget {
  const SignInMobileScreen({super.key});

  @override
  ConsumerState<SignInMobileScreen> createState() => _SignInMobileScreenState();
}

class _SignInMobileScreenState extends ConsumerState<SignInMobileScreen> {
  bool _showInvalid = false;

  void _onChanged(String value) {
    ref.read(signInMobileInputProvider.notifier).update(value);
    ref.read(signInEntryControllerProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    final mobile = ref.read(signInMobileInputProvider);
    if (!Validators.isValidMobile(mobile)) {
      setState(() => _showInvalid = true);
      return;
    }
    final sent = await ref.read(signInEntryControllerProvider.notifier).sendOtp();
    if (sent && mounted) context.go(RouteNames.signInVerify);
  }

  /// Opens registration, carrying the number over once it is complete.
  void _openSignUp() {
    final mobile = ref.read(signInMobileInputProvider);
    context.go(RouteNames.signupMobile, extra: Validators.isValidMobile(mobile) ? mobile : null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watching also keeps the typed number alive between keystrokes and the submit.
    final mobile = ref.watch(signInMobileInputProvider);
    final submit = ref.watch(signInEntryControllerProvider);
    final error = submit.error;
    final errorText = error != null
        ? signInErrorMessage(l10n, error)
        : _showInvalid && !Validators.isValidMobile(mobile)
            ? l10n.signupMobileInvalid
            : null;

    return AuthFormScaffold(
      onBack: () => context.go(RouteNames.createAccount),
      title: l10n.signInTitle,
      subtitle: l10n.signInSubtitle,
      content: [
        Text(l10n.signupMobileLabel, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        MobileNumberField(
          semanticLabel: l10n.signupMobileLabel,
          errorText: errorText,
          onChanged: _onChanged,
        ),
        if (error != null && signInNeedsAccount(error))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _openSignUp,
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                padding: EdgeInsets.zero,
              ),
              child: Text(l10n.signInCreateAccount, style: AppTextStyles.link),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.brandMutedText),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(l10n.signupMobileHint, style: AppTextStyles.hint)),
          ],
        ),
      ],
      bottom: Column(
        children: [
          BrandGradientButton(
            label: l10n.signupMobileSendOtp,
            isLoading: submit.isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthSwitchPrompt(
            prompt: l10n.signInNoAccount,
            actionLabel: l10n.signInSignUp,
            onPressed: _openSignUp,
          ),
        ],
      ),
    );
  }
}
