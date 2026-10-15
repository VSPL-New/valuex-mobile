import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/routing/post_aadhaar_route.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/field_error.dart';
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
class AadhaarScreen extends ConsumerStatefulWidget {
  const AadhaarScreen({super.key});

  @override
  ConsumerState<AadhaarScreen> createState() => _AadhaarScreenState();
}

class _AadhaarScreenState extends ConsumerState<AadhaarScreen> {
  final _formKey = GlobalKey();

  /// Brings the field and its messages to the top; they can sit below the fold.
  void _showErrors() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _formKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(target,
            duration: motionDuration(target, const Duration(milliseconds: 200)));
      }
    });
  }

  Future<void> _verify() async {
    final controller = ref.read(aadhaarFormProvider.notifier);
    if (!ref.read(aadhaarFormProvider).canVerify) {
      controller.showValidation();
      _showErrors();
      return;
    }
    final sent = await controller.sendOtp();
    if (!mounted) return;
    if (sent) {
      context.go(RouteNames.devAadhaarOtp);
    } else {
      _showErrors();
    }
  }

  Future<void> _skip(bool isLaterFlow) async {
    if (isLaterFlow) {
      context.go(_leaveRoute());
      return;
    }
    await ref.read(aadhaarFormProvider.notifier).skip();
  }

  /// Home, or the journey the seller was in when Aadhaar was asked for.
  String _leaveRoute() => ref.read(postAadhaarRouteProvider) ?? RouteNames.home;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final form = ref.watch(aadhaarFormProvider);
    final controller = ref.read(aadhaarFormProvider.notifier);
    final session = ref.watch(sessionControllerProvider).value;
    final serverError = form.error;
    final numberError = serverError != null
        ? authErrorMessage(l10n, serverError)
        : form.showValidation && !form.isNumberValid
            ? l10n.aadhaarNumberInvalid
            : null;
    final consentError = form.showValidation && !form.hasConsent;
    // Opened later from a gated action: the account is already past registration.
    final isLaterFlow = session is Authenticated && session.isPastRegistration;

    return ProtectedScreen(
      child: AuthFormScaffold(
        onBack: () => context.go(isLaterFlow ? _leaveRoute() : RouteNames.createAccount),
        title: l10n.aadhaarTitle,
        subtitle: l10n.aadhaarSubtitle,
        content: [
          AadhaarNoteCard(text: l10n.aadhaarNote),
          const SizedBox(height: AppSpacing.lg),
          if (config.useAadhaarSandbox)
            Column(
              key: _formKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.aadhaarNumberLabel, style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  label: l10n.aadhaarNumberLabel,
                  child: TextField(
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
                      error: numberError == null ? null : FieldError(text: numberError),
                      suffixIcon: IconButton(
                        tooltip: form.obscured ? l10n.aadhaarShowNumber : l10n.aadhaarHideNumber,
                        constraints: const BoxConstraints(
                            minWidth: AppSizes.minTouchTarget, minHeight: AppSizes.minTouchTarget),
                        onPressed: controller.toggleObscured,
                        icon: Icon(
                          form.obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.brandMutedText,
                        ),
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
                  side: BorderSide(
                    color: consentError ? AppColors.brandError : AppColors.brandControlBorder,
                    width: 2,
                  ),
                  title: Text(l10n.aadhaarConsent, style: AppTextStyles.bodySecondary),
                ),
                if (consentError) FieldError(text: l10n.aadhaarConsentRequired),
              ],
            )
          else
            Text(l10n.aadhaarComingSoon, style: AppTextStyles.bodySecondary),
        ],
        bottom: Column(
          children: [
            if (config.useAadhaarSandbox) ...[
              BrandGradientButton(
                label: l10n.aadhaarVerifyButton,
                isLoading: form.isSubmitting,
                onPressed: form.isSubmitting ? null : _verify,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SingleToneButton(
              label: isLaterFlow ? l10n.aadhaarNotNow : l10n.aadhaarSkip,
              onPressed: form.isSubmitting ? null : () => _skip(isLaterFlow),
            ),
          ],
        ),
      ),
    );
  }
}
