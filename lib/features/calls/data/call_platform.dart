import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's help for a call that is on (US-014, US-015): the screen stays awake and, on Android, the
/// app keeps the microphone and camera running while it is in the background. It never throws: a
/// phone without the help still takes the call.
abstract class CallPlatform {
  Future<void> begin({required bool video});

  Future<void> end();

  /// Rings while the call waits for an answer: the phone's ringtone and vibration for an incoming call,
  /// the ringback tone for the caller. Safe to call again; [stopRinging] ends it.
  Future<void> startRinging({required bool incoming});

  Future<void> stopRinging();
}

class MethodChannelCallPlatform implements CallPlatform {
  static const MethodChannel _channel = MethodChannel('com.valuex.valuex_mobile/call');

  const MethodChannelCallPlatform();

  @override
  Future<void> begin({required bool video}) => _invoke('begin', {'video': video});

  @override
  Future<void> end() => _invoke('end');

  @override
  Future<void> startRinging({required bool incoming}) =>
      _invoke('startRinging', {'incoming': incoming});

  @override
  Future<void> stopRinging() => _invoke('stopRinging');

  Future<void> _invoke(String method, [Map<String, Object?>? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // The call goes on without the help.
    } on MissingPluginException {
      // No native side (a test, or a platform without it).
    }
  }
}

final callPlatformProvider = Provider<CallPlatform>((ref) => const MethodChannelCallPlatform());
