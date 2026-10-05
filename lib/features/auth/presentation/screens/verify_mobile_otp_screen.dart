import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/masking.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/otp_verification_controller.dart';
import '../providers/registration_flow.dart';
import '../widgets/otp_verification_view.dart';

/// Registration step 2: enter the SMS code sent to the mobile number.
class VerifyMobileOtpScreen extends ConsumerWidget {
  const VerifyMobileOtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mobile = ref.watch(registrationFlowProvider.select((flow) => flow.mobile));

    if (mobile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RouteNames.signupMobile);
      });
      return const Scaffold();
    }

    return OtpVerificationView(
      channel: OtpChannel.mobile,
      title: l10n.otpMobileTitle,
      target: '+91 ${Masking.mobile(mobile)}',
      changeLabel: l10n.otpChangeNumber,
      onChange: () => context.go(RouteNames.signupMobile),
    );
  }
}
