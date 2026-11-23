import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/call_permissions.dart';
import '../../data/call_repository.dart';
import '../../domain/call.dart';

/// What pressing Call or Video gave: the call to open, or why there is none.
class CallLaunchResult {
  final String? callId;
  final CallPermissionResult? permission;
  final Object? error;

  const CallLaunchResult.started(String this.callId)
      : permission = null,
        error = null;
  const CallLaunchResult.refused(CallPermissionResult this.permission)
      : callId = null,
        error = null;
  const CallLaunchResult.failed(Object this.error)
      : callId = null,
        permission = null;

  /// A second tap while a request is running.
  const CallLaunchResult.ignored()
      : callId = null,
        permission = null,
        error = null;
}

/// Starts a call from a listing's Call or Video button (US-014, US-015). The permissions are asked
/// before the server is, and while a request runs the state is true so a second tap does nothing.
class CallLauncher extends Notifier<bool> {
  @override
  bool build() => false;

  Future<CallLaunchResult> start(String listingId, {required CallType type}) async {
    if (state) return const CallLaunchResult.ignored();
    state = true;
    try {
      final permission = await ref.read(callPermissionsProvider).request(video: type.hasVideo);
      if (permission != CallPermissionResult.granted) return CallLaunchResult.refused(permission);
      final call = await ref.read(callRepositoryProvider).start(listingId, type: type);
      return CallLaunchResult.started(call.callId);
    } on Object catch (error) {
      return CallLaunchResult.failed(error);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final callLauncherProvider = NotifierProvider<CallLauncher, bool>(CallLauncher.new);
