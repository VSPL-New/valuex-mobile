import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/registration_step.dart';
import '../../features/auth/presentation/providers/session_state.dart';
import 'route_names.dart';

/// Registration routes and the account steps allowed to show them.
const Map<String, Set<RegistrationStep>> _gatedRoutes = {
  RouteNames.signIn: {RegistrationStep.mobile},
  RouteNames.signInVerify: {RegistrationStep.mobile},
  RouteNames.googleMobile: {RegistrationStep.mobile},
  RouteNames.googleVerify: {RegistrationStep.mobile},
  RouteNames.signupMobile: {RegistrationStep.mobile},
  RouteNames.signupMobileVerify: {RegistrationStep.mobile},
  RouteNames.signupEmail: {RegistrationStep.email},
  RouteNames.signupEmailVerify: {RegistrationStep.email},
  RouteNames.signupAadhaar: {RegistrationStep.aadhaar},
  RouteNames.devAadhaarOtp: {RegistrationStep.aadhaar},
  RouteNames.signupProfile: {RegistrationStep.signup},
  RouteNames.terms: {RegistrationStep.signup},
  RouteNames.accountBlocked: {RegistrationStep.blocked},
  RouteNames.home: {RegistrationStep.home},
  RouteNames.categories: {RegistrationStep.home},
};

const Set<String> _aadhaarRoutes = {RouteNames.signupAadhaar, RouteNames.devAadhaarOtp};

String routeForStep(RegistrationStep step) {
  return switch (step) {
    RegistrationStep.mobile => RouteNames.signupMobile,
    RegistrationStep.email => RouteNames.signupEmail,
    RegistrationStep.aadhaar => RouteNames.signupAadhaar,
    RegistrationStep.signup => RouteNames.signupProfile,
    RegistrationStep.home => RouteNames.home,
    RegistrationStep.blocked => RouteNames.accountBlocked,
  };
}

/// First screen after the splash for a resolved session.
String startRouteFor(SessionState state) {
  return switch (state) {
    Unauthenticated() => RouteNames.onboarding,
    Authenticated(:final step) => routeForStep(step),
  };
}

/// GoRouter redirect: nobody sees a registration step the server status does not allow.
String? redirectFor({
  required AsyncValue<SessionState> session,
  required String location,
  bool aadhaarSandbox = true,
}) {
  final state = session.value;
  if (state == null) {
    return location == RouteNames.splash ? null : RouteNames.splash;
  }

  // The OTP screen exists only for the sandbox provider; production uses the third-party flow.
  if (location == RouteNames.devAadhaarOtp && !aadhaarSandbox) return RouteNames.signupAadhaar;

  final allowedSteps = _gatedRoutes[location];
  if (allowedSteps == null) return null;

  switch (state) {
    case Unauthenticated():
      // Signed-out users can enter the registration start and browse as guests.
      final open = allowedSteps.contains(RegistrationStep.mobile) ||
          allowedSteps.contains(RegistrationStep.home);
      return open ? null : RouteNames.createAccount;
    case Authenticated(:final step, :final aadhaarVerified):
      if (allowedSteps.contains(step)) return null;
      // Active users who skipped Aadhaar may open it later.
      final aadhaarLater =
          step == RegistrationStep.home && !aadhaarVerified && _aadhaarRoutes.contains(location);
      return aadhaarLater ? null : routeForStep(step);
  }
}
