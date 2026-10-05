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
class SignupMobileScreen extends ConsumerWidget {
  const SignupMobileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mobile = ref.watch(mobileInputProvider);
    final submit = ref.watch(mobileEntryControllerProvider);

    ref.listen(mobileEntryControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(authErrorMessage(l10n, error))));
    });

    return AuthFormScaffold(
      onBack: () => context.go(RouteNames.createAccount),
      title: l10n.signupMobileTitle,
      subtitle: l10n.signupMobileSubtitle,
      content: [
        Text(l10n.signupMobileLabel, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        MobileNumberField(onChanged: ref.read(mobileInputProvider.notifier).update),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.brandPlaceholder),
            const SizedBox(width: 6),
            Expanded(child: Text(l10n.signupMobileHint, style: AppTextStyles.hint)),
          ],
        ),
      ],
      bottom: BrandGradientButton(
        label: l10n.signupMobileSendOtp,
        isLoading: submit.isLoading,
        onPressed: Validators.isValidMobile(mobile)
            ? () async {
                final sent = await ref.read(mobileEntryControllerProvider.notifier).sendOtp();
                if (sent && context.mounted) context.go(RouteNames.signupMobileVerify);
              }
            : null,
      ),
    );
  }
}
