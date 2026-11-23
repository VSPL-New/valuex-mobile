import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// What the person answered when a call asked for the microphone and, for video, the camera.
enum CallPermissionResult {
  granted,

  /// The microphone is refused: no call is possible.
  microphoneDenied,

  /// The camera is refused: a video call is not possible, a voice call is.
  cameraDenied,

  /// Refused with "don't ask again": only the phone's settings can change it.
  permanentlyDenied,
}

/// Asks for the permissions of a call before any request is made to the server (US-014, US-015).
abstract class CallPermissions {
  Future<CallPermissionResult> request({required bool video});

  /// Opens the phone's settings page of this app.
  Future<void> openSettings();
}

class DeviceCallPermissions implements CallPermissions {
  const DeviceCallPermissions();

  @override
  Future<CallPermissionResult> request({required bool video}) async {
    final microphone = await Permission.microphone.request();
    if (!microphone.isGranted) {
      return microphone.isPermanentlyDenied
          ? CallPermissionResult.permanentlyDenied
          : CallPermissionResult.microphoneDenied;
    }
    if (!video) return CallPermissionResult.granted;
    final camera = await Permission.camera.request();
    if (camera.isGranted) return CallPermissionResult.granted;
    return camera.isPermanentlyDenied
        ? CallPermissionResult.permanentlyDenied
        : CallPermissionResult.cameraDenied;
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}

final callPermissionsProvider = Provider<CallPermissions>((ref) => const DeviceCallPermissions());
