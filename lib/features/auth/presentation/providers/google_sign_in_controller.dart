import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/google_sign_in_result.dart';
import 'auth_providers.dart';
import 'registration_flow.dart';
import 'session_controller.dart';

part 'google_sign_in_controller.g.dart';

enum GoogleSignInOutcome {
  /// The Google account was already linked and the session now reflects the account status.
  signedIn,

  /// A mobile number must be verified next.
  needsMobile,

  /// The user closed the Google account chooser.
  cancelled,
}

/// Turns a Google account into a ValueX session. The state carries the last error.
@riverpod
class GoogleSignInController extends _$GoogleSignInController {
  @override
  FutureOr<void> build() {}

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  /// [mockIdToken] replaces the Google account chooser when the backend runs the mock
  /// Google verifier (development only). Returns null when the attempt failed.
  Future<GoogleSignInOutcome?> signIn({String? mockIdToken}) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final idToken = mockIdToken ?? await ref.read(googleIdTokenSourceProvider).idToken();
      if (idToken == null) {
        if (ref.mounted) state = const AsyncData(null);
        return GoogleSignInOutcome.cancelled;
      }

      final result = await ref.read(authRepositoryProvider).signInWithGoogle(idToken);
      if (!ref.mounted) return null;
      state = const AsyncData(null);
      switch (result) {
        case GoogleSignedIn(:final auth):
          ref.read(sessionControllerProvider.notifier).signedIn(auth);
          return GoogleSignInOutcome.signedIn;
        case GoogleNeedsMobile(:final socialSessionToken, :final email):
          ref.read(registrationFlowProvider.notifier).googleSessionStarted(
                socialSessionToken: socialSessionToken,
                email: email,
              );
          return GoogleSignInOutcome.needsMobile;
      }
    } on Object catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
