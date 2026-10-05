import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';

/// Blocks screenshots and hides content in the app switcher while sensitive screens
/// (Aadhaar, and later payment and bank details) are showing.
abstract interface class ScreenProtectionService {
  Future<void> enable();

  Future<void> disable();
}

/// Protection is reference counted so a screen being replaced by another protected
/// screen never leaves a gap between the two.
class PluginScreenProtectionService implements ScreenProtectionService {
  int _holders = 0;

  @override
  Future<void> enable() async {
    _holders++;
    if (_holders != 1) return;
    await _run(() async {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    });
  }

  @override
  Future<void> disable() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders != 0) return;
    await _run(() async {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageWithBlurOff();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      developer.log('Screen protection call failed: $error', name: 'security');
    }
  }
}

final screenProtectionServiceProvider = Provider<ScreenProtectionService>(
  (ref) => PluginScreenProtectionService(),
);
