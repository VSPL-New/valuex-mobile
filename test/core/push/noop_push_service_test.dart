import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/push/push_service.dart';

void main() {
  test('the no-op service has nothing to ask, register or receive', () async {
    const service = NoopPushService();

    expect(service.isAvailable, isFalse);
    expect(await service.permissionGranted(), isFalse);
    expect(await service.requestPermission(), isFalse);
    expect(await service.token(), isNull);
    expect(await service.initialTap(), isNull);
    expect(await service.tokenChanges.isEmpty, isTrue);
    expect(await service.taps.isEmpty, isTrue);
    await expectLater(service.deleteToken(), completes);
  });
}
