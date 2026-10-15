import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_guard.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';

AsyncValue<SessionState> _signedOut() => const AsyncData<SessionState>(Unauthenticated());

AsyncValue<SessionState> _signedIn(AccountStatus status, {bool aadhaarVerified = false}) {
  return AsyncData(Authenticated(status: status, aadhaarVerified: aadhaarVerified));
}

void main() {
  group('while the session is unresolved', () {
    test('only the splash is reachable', () {
      const loading = AsyncLoading<SessionState>();
      expect(redirectFor(session: loading, location: RouteNames.splash), isNull);
      expect(redirectFor(session: loading, location: RouteNames.home), RouteNames.splash);
    });

    test('a failed lookup keeps the user on the splash', () {
      const failed = AsyncError<SessionState>(
        ApiError(type: ApiErrorType.network, message: ''),
        StackTrace.empty,
      );
      expect(redirectFor(session: failed, location: RouteNames.signupEmail), RouteNames.splash);
    });
  });

  group('signed out', () {
    test('can open the registration start, onboarding and guest home', () {
      for (final route in [
        RouteNames.onboarding,
        RouteNames.createAccount,
        RouteNames.signIn,
        RouteNames.signInVerify,
        RouteNames.googleMobile,
        RouteNames.googleVerify,
        RouteNames.signupMobile,
        RouteNames.signupMobileVerify,
        RouteNames.home,
      ]) {
        expect(redirectFor(session: _signedOut(), location: route), isNull, reason: route);
      }
    });

    test('cannot open steps that need an account', () {
      for (final route in [
        RouteNames.signupEmail,
        RouteNames.signupEmailVerify,
        RouteNames.signupAadhaar,
        RouteNames.devAadhaarOtp,
        RouteNames.signupProfile,
        RouteNames.terms,
        RouteNames.accountBlocked,
      ]) {
        expect(
          redirectFor(session: _signedOut(), location: route),
          RouteNames.createAccount,
          reason: route,
        );
      }
    });
  });

  group('resume by status', () {
    const resumeRoutes = {
      AccountStatus.emailVerificationPending: RouteNames.signupEmail,
      AccountStatus.identityVerificationPending: RouteNames.signupAadhaar,
      AccountStatus.signupPending: RouteNames.signupProfile,
      AccountStatus.active: RouteNames.home,
      AccountStatus.suspended: RouteNames.accountBlocked,
      AccountStatus.otpPending: RouteNames.signupMobile,
    };

    for (final entry in resumeRoutes.entries) {
      test('${entry.key.name} starts at ${entry.value}', () {
        expect(startRouteFor(_signedIn(entry.key).value!), entry.value);
        expect(redirectFor(session: _signedIn(entry.key), location: entry.value), isNull);
      });
    }

    test('signed out starts at onboarding', () {
      expect(startRouteFor(const Unauthenticated()), RouteNames.onboarding);
    });
  });

  group('never shows a step the status does not allow', () {
    test('an account waiting for email verification cannot see the mobile page', () {
      final session = _signedIn(AccountStatus.emailVerificationPending);
      expect(
        redirectFor(session: session, location: RouteNames.signupMobile),
        RouteNames.signupEmail,
      );
      expect(
        redirectFor(session: session, location: RouteNames.signupMobileVerify),
        RouteNames.signupEmail,
      );
    });

    test('skipping ahead to Sign Up is blocked before Aadhaar is handled', () {
      expect(
        redirectFor(
          session: _signedIn(AccountStatus.identityVerificationPending),
          location: RouteNames.signupProfile,
        ),
        RouteNames.signupAadhaar,
      );
    });

    test('a pending account cannot reach Home as a guest', () {
      expect(
        redirectFor(
          session: _signedIn(AccountStatus.signupPending),
          location: RouteNames.home,
        ),
        RouteNames.signupProfile,
      );
    });

    test('an active account cannot go back into registration', () {
      final session = _signedIn(AccountStatus.active, aadhaarVerified: true);
      expect(redirectFor(session: session, location: RouteNames.signupMobile), RouteNames.home);
      expect(redirectFor(session: session, location: RouteNames.signupProfile), RouteNames.home);
      expect(redirectFor(session: session, location: RouteNames.signupAadhaar), RouteNames.home);
    });

    test('a signed-in account never sees the Sign In or Google pages', () {
      for (final route in [
        RouteNames.signIn,
        RouteNames.signInVerify,
        RouteNames.googleMobile,
        RouteNames.googleVerify,
      ]) {
        expect(
          redirectFor(session: _signedIn(AccountStatus.active), location: route),
          RouteNames.home,
          reason: route,
        );
        expect(
          redirectFor(session: _signedIn(AccountStatus.signupPending), location: route),
          RouteNames.signupProfile,
          reason: route,
        );
        expect(
          redirectFor(session: _signedIn(AccountStatus.suspended), location: route),
          RouteNames.accountBlocked,
          reason: route,
        );
      }
    });

    test('a blocked account only sees the blocked page', () {
      final session = _signedIn(AccountStatus.banned);
      expect(redirectFor(session: session, location: RouteNames.home), RouteNames.accountBlocked);
    });
  });

  group('Aadhaar after skipping', () {
    test('an active account without Aadhaar can open the Aadhaar screens', () {
      final session = _signedIn(AccountStatus.active);
      expect(redirectFor(session: session, location: RouteNames.signupAadhaar), isNull);
      expect(redirectFor(session: session, location: RouteNames.devAadhaarOtp), isNull);
    });

    test('once verified, the Aadhaar screens return to the interrupted journey or Home', () {
      final verified = _signedIn(AccountStatus.active, aadhaarVerified: true);

      expect(
        redirectFor(
          session: verified,
          location: RouteNames.devAadhaarOtp,
          afterAadhaar: RouteNames.sell,
        ),
        RouteNames.sell,
      );
      expect(
        redirectFor(session: verified, location: RouteNames.signupAadhaar),
        RouteNames.home,
      );
    });

    test('the way back is not used while the account is still unverified', () {
      final session = _signedIn(AccountStatus.active);

      expect(
        redirectFor(
          session: session,
          location: RouteNames.signupAadhaar,
          afterAadhaar: RouteNames.sell,
        ),
        isNull,
      );
    });
  });

  group('ungated routes', () {
    test('onboarding and create account are never redirected', () {
      final session = _signedIn(AccountStatus.signupPending);
      expect(redirectFor(session: session, location: RouteNames.onboarding), isNull);
      expect(redirectFor(session: session, location: RouteNames.createAccount), isNull);
    });
  });

  group('Account Security and Notifications routes', () {
    const routes = [
      RouteNames.accountSecurity,
      RouteNames.changeMobile,
      RouteNames.changeEmail,
      RouteNames.notifications,
    ];

    test('signed-out users are sent to Sign In', () {
      for (final route in routes) {
        expect(redirectFor(session: _signedOut(), location: route), RouteNames.signIn,
            reason: route);
      }
    });

    test('active users, with or without Aadhaar, can open them', () {
      for (final route in routes) {
        for (final aadhaarVerified in [true, false]) {
          expect(
            redirectFor(
                session: _signedIn(AccountStatus.active, aadhaarVerified: aadhaarVerified),
                location: route),
            isNull,
            reason: route,
          );
        }
      }
    });

    test('a suspended account is sent to the blocked page', () {
      for (final route in routes) {
        expect(redirectFor(session: _signedIn(AccountStatus.suspended), location: route),
            RouteNames.accountBlocked,
            reason: route);
      }
    });
  });
}
