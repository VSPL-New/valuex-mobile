import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_messages.dart';
import '../providers/otp_verification_controller.dart';
import 'auth_form_scaffold.dart';

/// OTP step used for both the mobile and the email code.
class OtpVerificationView extends ConsumerWidget {
  final OtpChannel channel;
  final String title;
  final String target;
  final String changeLabel;
  final VoidCallback onChange;

  const OtpVerificationView({
    super.key,
    required this.channel,
    required this.title,
    required this.target,
    required this.changeLabel,
    required this.onChange,
  });

  static String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = otpVerificationControllerProvider(channel);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen(provider, (previous, next) {
      if (previous != null && next.sendCount > previous.sendCount) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.otpResent)));
      }
    });

    final error = state.error;
    final errorText = error == null
        ? null
        : channel == OtpChannel.login
            ? signInErrorMessage(l10n, error)
            : authErrorMessage(l10n, error);

    return AuthFormScaffold(
      onBack: onChange,
      title: title,
      subtitle: l10n.otpSubtitle(target),
      content: [
        OtpInput(
          // A new key empties the boxes when a new code is requested.
          key: ValueKey(state.sendCount),
          semanticLabel: l10n.otpFieldLabel,
          enabled: !state.isVerifying && !state.isLocked,
          hasError: error != null || state.codeIncomplete,
          onChanged: controller.setCode,
        ),
        const SizedBox(height: AppSpacing.md),
        if (errorText != null)
          FieldError(text: errorText)
        else if (state.codeIncomplete)
          FieldError(text: l10n.otpIncomplete)
        else if (state.isExpired)
          FieldError(text: l10n.otpExpired)
        else
          Text(l10n.otpExpiresIn(_formatTime(state.secondsUntilExpiry)), style: AppTextStyles.hint),
        const SizedBox(height: AppSpacing.md),
        _ResendRow(state: state, onResend: controller.resend),
      ],
      bottom: Column(
        children: [
          BrandGradientButton(
            label: l10n.otpVerify,
            isLoading: state.isVerifying,
            onPressed: state.canSubmit ? controller.verify : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
                minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget)),
            child: Text(
              changeLabel,
              style: AppTextStyles.link,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  final OtpVerificationState state;
  final VoidCallback onResend;

  const _ResendRow({required this.state, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.sendCount >= OtpVerificationController.maxSends && state.secondsUntilResend <= 0) {
      return Text(l10n.otpResendLimit, style: AppTextStyles.hint);
    }
    if (!state.canResend) {
      return Text(
        state.isResending ? l10n.otpResend : l10n.otpResendIn(state.secondsUntilResend),
        style: AppTextStyles.hint,
      );
    }
    return TextButton(
      onPressed: onResend,
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
      child: Text(
        l10n.otpResend,
        style: AppTextStyles.link,
      ),
    );
  }
}
