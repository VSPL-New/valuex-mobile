import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/security/screen_protection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('screen_protector'),
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('screen_protector'),
      null,
    );
  });

  test('turns protection on for the first screen and off after the last', () async {
    final service = PluginScreenProtectionService();

    await service.enable();
    expect(calls, contains('preventScreenshotOn'));
    calls.clear();

    await service.enable();
    expect(calls, isEmpty);

    await service.disable();
    expect(calls, isEmpty);

    await service.disable();
    expect(calls, contains('preventScreenshotOff'));
  });

  test('disabling without enabling does nothing', () async {
    final service = PluginScreenProtectionService();

    await service.disable();

    expect(calls, isEmpty);
  });

  test('a plugin failure does not throw into the screen', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('screen_protector'),
      (call) async => throw PlatformException(code: 'fail'),
    );
    final service = PluginScreenProtectionService();

    await expectLater(service.enable(), completes);
  });
}
