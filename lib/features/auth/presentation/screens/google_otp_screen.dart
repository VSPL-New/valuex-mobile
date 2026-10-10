import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/masking.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/otp_verification_controller.dart';
import '../providers/registration_flow.dart';
import '../widgets/otp_verification_view.dart';

/// Google sign-in, step 2: the SMS code. Success signs the user in and the router opens the
/// screen that matches the account status.
class GoogleOtpScreen extends ConsumerWidget {
  const GoogleOtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final flow = ref.watch(registrationFlowProvider);
    final mobile = flow.mobile;

    if (mobile == null || flow.socialSessionToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RouteNames.createAccount);
      });
      return const Scaffold();
    }

    return OtpVerificationView(
      channel: OtpChannel.googleLink,
      title: l10n.otpMobileTitle,
      target: '+91 ${Masking.mobile(mobile)}',
      changeLabel: l10n.otpChangeNumber,
      onChange: () => context.go(RouteNames.googleMobile),
    );
  }
}
