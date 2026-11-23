import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/calls/data/call_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.valuex.valuex_mobile/call');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('begin, end and ringing reach the phone', () async {
    final seen = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      seen.add(call);
      return null;
    });

    await const MethodChannelCallPlatform().begin(video: true);
    await const MethodChannelCallPlatform().end();
    await const MethodChannelCallPlatform().startRinging(incoming: true);
    await const MethodChannelCallPlatform().stopRinging();

    expect(seen.map((call) => call.method), ['begin', 'end', 'startRinging', 'stopRinging']);
    expect(seen.first.arguments, {'video': true});
    expect(seen[2].arguments, {'incoming': true});
  });

  test('a phone that refuses the help does not stop the call', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'denied');
    });

    await const MethodChannelCallPlatform().begin(video: false);
    await const MethodChannelCallPlatform().end();
  });

  test('a platform without the native side does not stop the call', () async {
    await const MethodChannelCallPlatform().begin(video: false);
    await const MethodChannelCallPlatform().end();
  });
}
