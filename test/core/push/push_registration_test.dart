import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/constants/api_constants.dart';
import 'package:valuex_mobile/core/push/push_providers.dart';
import 'package:valuex_mobile/core/push/push_service.dart';
import 'package:valuex_mobile/core/push/push_token_repository.dart';

import '../../helpers/mocks.dart';
import 'push_fakes.dart';

class _MockRepository extends Mock implements PushTokenRepository {}

void main() {
  late FakePushService service;
  late _MockRepository repository;
  var locale = 'en';

  setUp(() {
    service = FakePushService()..token_ = 'fcm-1';
    repository = _MockRepository();
    locale = 'en';
    when(() => repository.register(
          deviceId: any(named: 'deviceId'),
          platform: any(named: 'platform'),
          token: any(named: 'token'),
          locale: any(named: 'locale'),
          appVersion: any(named: 'appVersion'),
          permissionGranted: any(named: 'permissionGranted'),
        )).thenAnswer((_) async {});
    when(() => repository.unregister(any())).thenAnswer((_) async {});
  });

  PushRegistration registration() => PushRegistration(
        service: service,
        repository: repository,
        installId: () async => 'install-1',
        locale: () => locale,
        platform: 'ANDROID',
      );

  group('sync', () {
    test('registers the token with the install id, platform, language and permission', () async {
      locale = 'hi';
      service.granted = true;

      await registration().sync();

      verify(() => repository.register(
            deviceId: 'install-1',
            platform: 'ANDROID',
            token: 'fcm-1',
            locale: 'hi',
            appVersion: any(named: 'appVersion'),
            permissionGranted: true,
          )).called(1);
    });

    test('tells the server when notifications are not allowed', () async {
      service.granted = false;

      await registration().sync();

      verify(() => repository.register(
            deviceId: any(named: 'deviceId'),
            platform: any(named: 'platform'),
            token: any(named: 'token'),
            locale: any(named: 'locale'),
            appVersion: any(named: 'appVersion'),
            permissionGranted: false,
          )).called(1);
    });

    test('does nothing while the phone has no token yet', () async {
      service.token_ = null;

      await registration().sync();

      verifyNever(() => repository.register(
            deviceId: any(named: 'deviceId'),
            platform: any(named: 'platform'),
            token: any(named: 'token'),
            locale: any(named: 'locale'),
            appVersion: any(named: 'appVersion'),
            permissionGranted: any(named: 'permissionGranted'),
          ));
    });

    test('does nothing where push is not available', () async {
      final off = PushRegistration(
        service: const NoopPushService(),
        repository: repository,
        installId: () async => 'install-1',
        locale: () => 'en',
        platform: 'ANDROID',
      );

      await off.sync();

      verifyNever(() => repository.register(
            deviceId: any(named: 'deviceId'),
            platform: any(named: 'platform'),
            token: any(named: 'token'),
            locale: any(named: 'locale'),
            appVersion: any(named: 'appVersion'),
            permissionGranted: any(named: 'permissionGranted'),
          ));
    });

    test('a failure never reaches the caller', () async {
      when(() => repository.register(
            deviceId: any(named: 'deviceId'),
            platform: any(named: 'platform'),
            token: any(named: 'token'),
            locale: any(named: 'locale'),
            appVersion: any(named: 'appVersion'),
            permissionGranted: any(named: 'permissionGranted'),
          )).thenThrow(StateError('offline'));

      await expectLater(registration().sync(), completes);
    });
  });

  group('unregister', () {
    test('removes the tokens of this install at sign-out', () async {
      await registration().unregister();

      verify(() => repository.unregister('install-1')).called(1);
    });

    test('a failure never reaches the caller', () async {
      when(() => repository.unregister(any())).thenThrow(StateError('offline'));

      await expectLater(registration().unregister(), completes);
    });

    test('does not hold sign-out up for more than a few seconds', () {
      fakeAsync((async) {
        when(() => repository.unregister(any())).thenAnswer((_) => Completer<void>().future);
        var done = false;

        registration().unregister().then((_) => done = true);
        async.flushMicrotasks();
        expect(done, isFalse);
        async.elapse(const Duration(seconds: 4));

        expect(done, isTrue);
      });
    });

    test('does nothing where push is not available', () async {
      final off = PushRegistration(
        service: const NoopPushService(),
        repository: repository,
        installId: () async => 'install-1',
        locale: () => 'en',
        platform: 'ANDROID',
      );

      await off.unregister();

      verifyNever(() => repository.unregister(any()));
    });
  });

  test('forget drops the token on the phone', () async {
    await registration().forget();

    expect(service.deleted, 1);
  });

  group('PushTokenRepository', () {
    test('registers with a PUT carrying every field and removes with a DELETE', () async {
      final client = MockApiClient();
      when(() => client.put<void>(any(), data: any(named: 'data'))).thenAnswer((_) async {});
      when(() => client.delete<void>(any(), data: any(named: 'data'))).thenAnswer((_) async {});
      final repo = PushTokenRepository(client);

      await repo.register(
        deviceId: 'd',
        platform: 'IOS',
        token: 't',
        locale: 'hi',
        appVersion: '0.1.0',
        permissionGranted: false,
      );
      await repo.unregister('d');

      verify(() => client.put<void>(ApiConstants.devicePushToken, data: {
            'deviceId': 'd',
            'platform': 'IOS',
            'token': 't',
            'locale': 'hi',
            'appVersion': '0.1.0',
            'permissionGranted': false,
          })).called(1);
      verify(() => client.delete<void>(ApiConstants.devicePushToken, data: {'deviceId': 'd'}))
          .called(1);
    });
  });
}
