import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// "Resend code" line under an OTP input: a countdown, the resend link, or the resend limit.
class OtpResendRow extends StatelessWidget {
  final int sendCount;
  final int maxSends;
  final int secondsUntilResend;
  final bool canResend;
  final bool isResending;
  final VoidCallback onResend;

  const OtpResendRow({
    super.key,
    required this.sendCount,
    required this.maxSends,
    required this.secondsUntilResend,
    required this.canResend,
    required this.isResending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (sendCount >= maxSends && secondsUntilResend <= 0) {
      return Text(l10n.otpResendLimit, style: AppTextStyles.hint);
    }
    if (!canResend) {
      return Text(
        isResending ? l10n.otpResend : l10n.otpResendIn(secondsUntilResend),
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
