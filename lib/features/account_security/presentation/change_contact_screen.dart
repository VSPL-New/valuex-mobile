import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/otp_input.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/mobile_number_field.dart';
import '../../auth/presentation/widgets/otp_resend_row.dart';
import '../domain/account_security.dart';
import 'providers/contact_change_controller.dart';
import 'security_error_messages.dart';

/// Change the mobile number or email: enter the new value, then confirm the code sent to it.
/// The current value stays active until the code is confirmed.
class ChangeContactScreen extends ConsumerWidget {
  final ContactKind kind;

  const ChangeContactScreen({super.key, required this.kind});

  static String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.accountSecurity);
    }
  }

  Future<void> _verify(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = await ref.read(contactChangeControllerProvider(kind).notifier).verify();
    if (!done) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            kind == ContactKind.mobile ? l10n.securityMobileUpdated : l10n.securityEmailUpdated,
          ),
        ),
      );
    if (context.mounted) _close(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = contactChangeControllerProvider(kind);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final isMobile = kind == ContactKind.mobile;
    final inCodeStep = state.step == ContactChangeStep.code;

    ref.listen(provider, (previous, next) {
      if (previous != null && next.sendCount > previous.sendCount && previous.sendCount > 0) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.otpResent)));
      }
    });

    final title = inCodeStep
        ? (isMobile ? l10n.securityConfirmMobileTitle : l10n.securityConfirmEmailTitle)
        : (isMobile ? l10n.securityChangeMobileTitle : l10n.securityChangeEmailTitle);

    void back() {
      if (state.isBusy) return;
      if (inCodeStep) {
        controller.editValue();
      } else {
        _close(context);
      }
    }

    return PopScope(
      canPop: !inCodeStep && !state.isBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(title, style: AppTextStyles.heading2)),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: state.isBusy ? null : back,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: inCodeStep
                          ? _codeStep(context, l10n, state, controller)
                          : _entryStep(context, l10n, state, controller),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (inCodeStep)
                  Column(
                    children: [
                      BrandGradientButton(
                        label: l10n.otpVerify,
                        isLoading: state.isBusy,
                        onPressed: state.canVerify ? () => _verify(context, ref) : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: state.isBusy ? null : controller.editValue,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                        ),
                        child: Text(
                          isMobile ? l10n.otpChangeNumber : l10n.otpChangeEmail,
                          style: AppTextStyles.link,
                        ),
                      ),
                    ],
                  )
                else
                  BrandGradientButton(
                    label: l10n.securitySendCode,
                    isLoading: state.isBusy,
                    onPressed: controller.sendCode,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _entryStep(
    BuildContext context,
    AppLocalizations l10n,
    ContactChangeState state,
    ContactChangeController controller,
  ) {
    final isMobile = kind == ContactKind.mobile;
    final error = state.error;
    final errorText = error != null
        ? securityErrorMessage(l10n, error)
        : state.showInvalid
            ? (isMobile ? l10n.signupMobileInvalid : l10n.emailEntryInvalid)
            : null;
    final label = isMobile ? l10n.securityNewMobileLabel : l10n.securityNewEmailLabel;

    return [
      Text(
        isMobile ? l10n.securityChangeMobileSubtitle : l10n.securityChangeEmailSubtitle,
        style: AppTextStyles.bodySecondary,
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: AppSpacing.sm),
      if (isMobile)
        MobileNumberField(
          semanticLabel: label,
          errorText: errorText,
          initialValue: state.value,
          onChanged: controller.setValue,
        )
      else
        Semantics(
          label: label,
          child: TextFormField(
            initialValue: state.value,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onChanged: controller.setValue,
            onFieldSubmitted: (_) => controller.sendCode(),
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: l10n.emailEntryFieldHint,
              error: errorText == null ? null : FieldError(text: errorText),
            ),
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
          Expanded(
            child: Text(
              isMobile ? l10n.securityMobileStaysActive : l10n.securityEmailStaysActive,
              style: AppTextStyles.hint,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _codeStep(
    BuildContext context,
    AppLocalizations l10n,
    ContactChangeState state,
    ContactChangeController controller,
  ) {
    final error = state.error;
    final errorText = error == null ? null : securityErrorMessage(l10n, error);
    final target = kind == ContactKind.mobile ? '+91 ${state.value}' : state.value;

    return [
      Text(l10n.otpSubtitle(target), style: AppTextStyles.bodySecondary),
      const SizedBox(height: AppSpacing.lg),
      OtpInput(
        // A new key empties the boxes when a new code is requested.
        key: ValueKey(state.sendCount),
        semanticLabel: l10n.otpFieldLabel,
        enabled: !state.isBusy && !state.isLocked,
        hasError: error != null || state.showInvalid,
        onChanged: controller.setCode,
      ),
      const SizedBox(height: AppSpacing.md),
      if (errorText != null)
        FieldError(text: errorText)
      else if (state.showInvalid)
        FieldError(text: l10n.otpIncomplete)
      else if (state.isExpired)
        FieldError(text: l10n.otpExpired)
      else
        Text(l10n.otpExpiresIn(_formatTime(state.secondsUntilExpiry)), style: AppTextStyles.hint),
      const SizedBox(height: AppSpacing.md),
      OtpResendRow(
        sendCount: state.sendCount,
        maxSends: ContactChangeController.maxSends,
        secondsUntilResend: state.secondsUntilResend,
        canResend: state.canResend,
        isResending: state.isBusy,
        onResend: controller.resend,
      ),
    ];
  }
}
