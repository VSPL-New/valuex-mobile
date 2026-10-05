import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/provider_retry.dart';
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
    final subscription = ref.watch(apiClientProvider).onSessionExpired.listen((_) {
      state = const AsyncData(Unauthenticated(sessionExpired: true));
    });
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
}
