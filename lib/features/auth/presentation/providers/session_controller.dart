import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_event.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/auth_session.dart';
import 'auth_providers.dart';
import 'session_state.dart';

part 'session_controller.g.dart';

/// Account state of the signed-in user. Loading and error describe the startup
/// lookup; routing decisions come from the server status, not from cached screens.
@Riverpod(keepAlive: true, retry: noAutoRetry)
class SessionController extends _$SessionController {
  @override
  Future<SessionState> build() async {
    final subscription = ref.watch(apiClientProvider).sessionEvents.listen(_onSessionEvent);
    ref.onDispose(subscription.cancel);

    final profile = await ref.watch(restoreSessionProvider).call();
    if (profile == null) return const Unauthenticated();
    return Authenticated(status: profile.status, aadhaarVerified: profile.aadhaarVerified);
  }

  /// Call after an endpoint issued tokens (verify mobile, skip or verify Aadhaar).
  void signedIn(AuthResult result) {
    state = AsyncData(
      Authenticated(status: result.status, aadhaarVerified: result.aadhaarVerified),
    );
  }

  /// Re-reads the status from the server after a step that returns no tokens.
  Future<void> refreshStatus() async {
    final profile = await ref.read(authRepositoryProvider).fetchProfile();
    state = AsyncData(
      Authenticated(status: profile.status, aadhaarVerified: profile.aadhaarVerified),
    );
  }

  Future<void> signOutLocally() async {
    await ref.read(authRepositoryProvider).clearSession();
    state = const AsyncData(Unauthenticated());
  }

  void _onSessionEvent(SessionEvent event) {
    switch (event) {
      case SessionEnded(:final reason):
        final current = state.value;
        final aadhaarVerified = current is Authenticated && current.aadhaarVerified;
        state = AsyncData(switch (reason) {
          SessionEndReason.expired => const Unauthenticated(sessionExpired: true),
          // The tokens are gone, so the blocked screen only offers returning to Sign In.
          SessionEndReason.suspended =>
            Authenticated(status: AccountStatus.suspended, aadhaarVerified: aadhaarVerified),
          SessionEndReason.recoveryRequired =>
            Authenticated(status: AccountStatus.banned, aadhaarVerified: aadhaarVerified),
        });
      case SessionRefreshed(:final status, :final aadhaarVerified):
        final current = state.value;
        if (current is! Authenticated) return;
        final next = Authenticated(
          status: status == null ? current.status : AccountStatus.fromApi(status),
          aadhaarVerified: aadhaarVerified ?? current.aadhaarVerified,
        );
        if (next.status == current.status && next.aadhaarVerified == current.aadhaarVerified) {
          return;
        }
        state = AsyncData(next);
    }
  }
}
