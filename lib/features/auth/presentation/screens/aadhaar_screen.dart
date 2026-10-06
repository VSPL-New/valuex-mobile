import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/protected_screen.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_messages.dart';
import '../providers/aadhaar_controllers.dart';
import '../providers/session_controller.dart';
import '../providers/session_state.dart';
import '../widgets/aadhaar_note_card.dart';
import '../widgets/auth_form_scaffold.dart';

/// Registration step 5: verify Aadhaar now, or skip and verify before the first transaction.
class AadhaarScreen extends ConsumerWidget {
  const AadhaarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final form = ref.watch(aadhaarFormProvider);
    final controller = ref.read(aadhaarFormProvider.notifier);
    final session = ref.watch(sessionControllerProvider).value;
    // Opened later from a gated action: the account is already past registration.
    final isLaterFlow = session is Authenticated && session.isPastRegistration;

    ref.listen(aadhaarFormProvider.select((state) => state.error), (previous, error) {
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(authErrorMessage(l10n, error))));
    });

    Future<void> verify() async {
      final sent = await controller.sendOtp();
      if (sent && context.mounted) {
        context.go(RouteNames.devAadhaarOtp);
      }
    }

    Future<void> skip() async {
      if (isLaterFlow) {
        context.go(RouteNames.home);
        return;
      }
      await controller.skip();
    }

    return ProtectedScreen(
      child: AuthFormScaffold(
        onBack: () => context.go(isLaterFlow ? RouteNames.home : RouteNames.createAccount),
        title: l10n.aadhaarTitle,
        subtitle: l10n.aadhaarSubtitle,
        content: [
          AadhaarNoteCard(text: l10n.aadhaarNote),
          const SizedBox(height: AppSpacing.lg),
          if (config.useAadhaarSandbox) ...[
            Text(l10n.aadhaarNumberLabel, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              obscureText: form.obscured,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              onChanged: controller.setNumber,
              style: AppTextStyles.input,
              cursorColor: AppColors.brandPrimary,
              decoration: InputDecoration(
                hintText: l10n.aadhaarNumberHint,
                suffixIcon: IconButton(
                  tooltip: form.obscured ? l10n.aadhaarShowNumber : l10n.aadhaarHideNumber,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: controller.toggleObscured,
                  icon: Icon(
                    form.obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.brandMutedText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: form.hasConsent,
              onChanged: (value) => controller.setConsent(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.brandPrimary,
              title: Text(l10n.aadhaarConsent, style: AppTextStyles.bodySecondary),
            ),
          ] else
            Text(l10n.aadhaarComingSoon, style: AppTextStyles.bodySecondary),
        ],
        bottom: Column(
          children: [
            if (config.useAadhaarSandbox) ...[
              BrandGradientButton(
                label: l10n.aadhaarVerifyButton,
                isLoading: form.isSubmitting,
                onPressed: form.canVerify ? verify : null,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SingleToneButton(
              label: isLaterFlow ? l10n.aadhaarNotNow : l10n.aadhaarSkip,
              onPressed: form.isSubmitting ? null : skip,
            ),
          ],
        ),
      ),
    );
  }
}
