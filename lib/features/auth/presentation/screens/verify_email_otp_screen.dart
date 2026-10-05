import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/masking.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/otp_verification_controller.dart';
import '../providers/registration_flow.dart';
import '../widgets/otp_verification_view.dart';

/// Registration step 4: enter the code sent to the email address.
class VerifyEmailOtpScreen extends ConsumerWidget {
  const VerifyEmailOtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final email = ref.watch(registrationFlowProvider.select((flow) => flow.email));

    if (email == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RouteNames.signupEmail);
      });
      return const Scaffold();
    }

    return OtpVerificationView(
      channel: OtpChannel.email,
      title: l10n.otpEmailTitle,
      target: Masking.email(email),
      changeLabel: l10n.otpChangeEmail,
      onChange: () => context.go(RouteNames.signupEmail),
    );
  }
}
