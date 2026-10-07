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
import '../widgets/mobile_number_field.dart';

/// Registration step 1: enter a mobile number to receive an OTP
/// (Figma Make: signup-phone "Create Account").
class SignupMobileScreen extends ConsumerStatefulWidget {
  const SignupMobileScreen({super.key});

  @override
  ConsumerState<SignupMobileScreen> createState() => _SignupMobileScreenState();
}

class _SignupMobileScreenState extends ConsumerState<SignupMobileScreen> {
  bool _showInvalid = false;

  void _onChanged(String value) {
    ref.read(mobileInputProvider.notifier).update(value);
    ref.read(mobileEntryControllerProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    final mobile = ref.read(mobileInputProvider);
    if (!Validators.isValidMobile(mobile)) {
      setState(() => _showInvalid = true);
      return;
    }
    final sent = await ref.read(mobileEntryControllerProvider.notifier).sendOtp();
    if (sent && mounted) context.go(RouteNames.signupMobileVerify);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watching also keeps the typed number alive between keystrokes and the submit.
    final mobile = ref.watch(mobileInputProvider);
    final submit = ref.watch(mobileEntryControllerProvider);
    final error = submit.error;
    final errorText = error != null
        ? authErrorMessage(l10n, error)
        : _showInvalid && !Validators.isValidMobile(mobile)
            ? l10n.signupMobileInvalid
            : null;

    return AuthFormScaffold(
      onBack: () => context.go(RouteNames.createAccount),
      title: l10n.signupMobileTitle,
      subtitle: l10n.signupMobileSubtitle,
      content: [
        Text(l10n.signupMobileLabel, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        MobileNumberField(
          semanticLabel: l10n.signupMobileLabel,
          errorText: errorText,
          onChanged: _onChanged,
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
      bottom: BrandGradientButton(
        label: l10n.signupMobileSendOtp,
        isLoading: submit.isLoading,
        onPressed: _submit,
      ),
    );
  }
}
