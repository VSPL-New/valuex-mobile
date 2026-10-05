import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
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

    return AuthFormScaffold(
      onBack: onChange,
      title: title,
      subtitle: l10n.otpSubtitle(target),
      content: [
        OtpInput(
          semanticLabel: l10n.otpFieldLabel,
          enabled: !state.isVerifying && !state.isLocked,
          hasError: error != null,
          onChanged: controller.setCode,
        ),
        const SizedBox(height: AppSpacing.md),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              authErrorMessage(l10n, error),
              style: AppTextStyles.hint.copyWith(color: AppColors.brandError),
            ),
          )
        else
          Text(
            state.isExpired
                ? l10n.otpExpired
                : l10n.otpExpiresIn(_formatTime(state.secondsUntilExpiry)),
            style: AppTextStyles.hint,
          ),
        const SizedBox(height: AppSpacing.md),
        _ResendRow(state: state, onResend: controller.resend),
      ],
      bottom: Column(
        children: [
          BrandGradientButton(
            label: l10n.otpVerify,
            isLoading: state.isVerifying,
            onPressed: state.canVerify ? controller.verify : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text(
              changeLabel,
              style: AppTextStyles.input.copyWith(color: AppColors.brandPrimary),
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
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
      child: Text(
        l10n.otpResend,
        style: AppTextStyles.input.copyWith(color: AppColors.brandPrimary),
      ),
    );
  }
}
