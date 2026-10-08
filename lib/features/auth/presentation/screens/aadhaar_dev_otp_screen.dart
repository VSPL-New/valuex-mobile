// TO BE REPLACED with the third-party Aadhaar verification service provider.
// Development only: used with the sandbox Aadhaar provider (AADHAAR_FLOW=sandbox).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../../../core/widgets/protected_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_messages.dart';
import '../providers/aadhaar_controllers.dart';
import '../providers/registration_flow.dart';
import '../widgets/auth_form_scaffold.dart';

/// Development-only Aadhaar OTP step, clearly marked on screen.
class AadhaarDevOtpScreen extends ConsumerWidget {
  const AadhaarDevOtpScreen({super.key});

  static const _sessionErrors = {'ERROR_AADHAAR_SESSION_EXPIRED', 'ERROR_INVALID_TRANSACTION'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final transactionId = ref.watch(
      registrationFlowProvider.select((flow) => flow.aadhaarTransactionId),
    );
    final state = ref.watch(aadhaarOtpControllerProvider);
    final controller = ref.read(aadhaarOtpControllerProvider.notifier);

    if (transactionId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RouteNames.signupAadhaar);
      });
      return const Scaffold();
    }

    ref.listen(aadhaarOtpControllerProvider.select((value) => value.error), (previous, error) {
      if (error == null || !context.mounted) return;
      // The message must outlive the screen when the transaction is gone.
      if (_sessionErrors.contains(error.code)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(l10n, error))));
        context.go(RouteNames.signupAadhaar);
      }
    });

    return ProtectedScreen(
      child: AuthFormScaffold(
        onBack: () => context.go(RouteNames.signupAadhaar),
        title: l10n.aadhaarOtpTitle,
        subtitle: l10n.aadhaarOtpSubtitle,
        content: [
          Container(
            key: const Key('aadhaarDevBanner'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.brandSurfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.brandAccent, width: 2),
            ),
            child: Text(
              l10n.aadhaarDevBanner,
              style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          OtpInput(
            semanticLabel: l10n.otpFieldLabel,
            enabled: !state.isVerifying,
            hasError: state.error != null || state.codeIncomplete,
            onChanged: controller.setCode,
          ),
          if (state.error != null || state.codeIncomplete) ...[
            const SizedBox(height: AppSpacing.md),
            FieldError(
              text: state.error != null ? authErrorMessage(l10n, state.error!) : l10n.otpIncomplete,
            ),
          ],
        ],
        bottom: Column(
          children: [
            BrandGradientButton(
              label: l10n.otpVerify,
              isLoading: state.isVerifying,
              onPressed: state.isVerifying ? null : controller.verify,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go(RouteNames.signupAadhaar),
              style: TextButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget)),
              child: Text(
                l10n.aadhaarChangeNumber,
                style: AppTextStyles.link,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
