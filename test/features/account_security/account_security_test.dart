import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/account_security/data/account_security_repository.dart';
import 'package:valuex_mobile/features/account_security/domain/account_security.dart';
import 'package:valuex_mobile/features/account_security/presentation/account_security_screen.dart';
import 'package:valuex_mobile/features/account_security/presentation/change_contact_screen.dart';
import 'package:valuex_mobile/features/account_security/presentation/providers/contact_change_controller.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/profile/presentation/widgets/profile_menu_section.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements AccountSecurityRepository {}

const _pending = AccountSecurity(
  mobile: '90XXXX0060',
  email: 'us***@example.com',
  aadhaarVerified: false,
);

const _verified = AccountSecurity(
  mobile: '90XXXX0060',
  email: 'us***@example.com',
  aadhaarVerified: true,
);

final _thisDevice = ActiveSession(
  id: 'session-1',
  deviceInfo: 'JustQlic/0.1.0 (iOS)',
  ipAddress: '10.0.0.5',
  lastActiveAt: DateTime(2026, 10, 13, 10, 30),
  isCurrent: true,
);

final _otherDevice = ActiveSession(
  id: 'session-2',
  deviceInfo: 'Mozilla/5.0 (Linux; Android 15)',
  ipAddress: '10.0.0.9',
  lastActiveAt: DateTime(2026, 10, 12, 8, 15),
  isCurrent: false,
);

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

ApiError _business(String code) => ApiError(type: ApiErrorType.business, message: code, code: code);

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

void main() {
  setUpAll(() {
    loadBrandFonts();
    registerFallbackValue(ContactKind.mobile);
  });

  group('ActiveSession.deviceName', () {
    ActiveSession session(String? info) =>
        ActiveSession(id: 'id', deviceInfo: info, isCurrent: false);

    test('names the app and platform from its own User-Agent', () {
      expect(session('JustQlic/0.1.0 (iOS)').deviceName, 'JustQlic \u00B7 iOS');
    });

    test('has no name for a missing or Dart default User-Agent', () {
      expect(session(null).deviceName, isNull);
      expect(session('  ').deviceName, isNull);
      expect(session('Dart/3.9 (dart:io)').deviceName, isNull);
    });

    test('shows any other User-Agent as sent, shortened when long', () {
      expect(session('Swagger').deviceName, 'Swagger');
      expect(session('x' * 80).deviceName, '${'x' * 60}\u2026');
    });
  });

  group('repository', () {
    late FakeHttpAdapter adapter;
    late AccountSecurityRepository repository;

    setUp(() {
      adapter = FakeHttpAdapter((options) async {
        return switch (options.path) {
          '/users/me/account-security' => FakeHttpAdapter.ok({
              'mobile': '90XXXX0060',
              'email': 'us***@example.com',
              'aadhaarVerified': true,
              'deleteAccountUrl': '/api/v1/users/me/deletion-request',
            }),
          '/users/me/sessions' => FakeHttpAdapter.ok([
              {
                'sessionId': 's1',
                'deviceInfo': 'JustQlic/0.1.0 (iOS)',
                'ipAddress': '10.0.0.5',
                'createdAt': '2026-10-13T08:00:00Z',
                'lastActiveAt': '2026-10-13T09:00:00Z',
                'current': true,
              },
              {'sessionId': 's2', 'isCurrent': false, 'lastActiveAt': 'not a date'},
            ]),
          '/users/me/mobile/change/initiate' ||
          '/users/me/email/change/initiate' =>
            FakeHttpAdapter.ok({'message': 'OTP sent', 'otpExpiresInSeconds': 300}),
          _ => FakeHttpAdapter.ok({'message': 'ok'}),
        };
      });
      final client = ApiClient(
        FakeSecureStorage(accessToken: 'access-1', refreshToken: 'refresh-1'),
        _config,
        adapter: adapter,
      );
      repository = AccountSecurityRepository(client);
    });

    test('summary reads the masked values and the Aadhaar status', () async {
      final summary = await repository.summary();

      expect(summary.mobile, '90XXXX0060');
      expect(summary.email, 'us***@example.com');
      expect(summary.aadhaarVerified, isTrue);
    });

    test('sessions read the backend `current` flag and tolerate `isCurrent`', () async {
      final sessions = await repository.sessions();

      expect(sessions.map((s) => s.id), ['s1', 's2']);
      expect(sessions[0].isCurrent, isTrue);
      expect(sessions[0].lastActiveAt, DateTime.utc(2026, 10, 13, 9).toLocal());
      expect(sessions[1].isCurrent, isFalse);
      expect(sessions[1].lastActiveAt, isNull);
    });

    test('starting a mobile change sends only the new number', () async {
      final sent = await repository.startChange(ContactKind.mobile, '9000000061');

      expect(sent.expiresInSeconds, 300);
      final request = adapter.requests.single;
      expect(request.path, '/users/me/mobile/change/initiate');
      expect(request.data, {'newMobile': '9000000061'});
      expect(request.headers['Authorization'], 'Bearer access-1');
    });

    test('starting an email change sends only the new address', () async {
      await repository.startChange(ContactKind.email, 'new@example.com');

      final request = adapter.requests.single;
      expect(request.path, '/users/me/email/change/initiate');
      expect(request.data, {'newEmail': 'new@example.com'});
    });

    test('confirming a change sends the new value with the code', () async {
      await repository.confirmChange(ContactKind.mobile, '9000000061', '123456');
      await repository.confirmChange(ContactKind.email, 'new@example.com', '654321');

      expect(adapter.requests[0].path, '/users/me/mobile/change/verify');
      expect(adapter.requests[0].data, {'newMobile': '9000000061', 'otp': '123456'});
      expect(adapter.requests[1].path, '/users/me/email/change/verify');
      expect(adapter.requests[1].data, {'newEmail': 'new@example.com', 'otp': '654321'});
    });

    test('logging out other devices posts without a body', () async {
      await repository.revokeOtherSessions();

      final request = adapter.requests.single;
      expect(request.path, '/users/me/sessions/revoke-others');
      expect(request.method, 'POST');
    });

    test('every request names the app and platform in its User-Agent', () async {
      await repository.summary();

      expect(adapter.requests.single.headers['User-Agent'], startsWith('JustQlic/0.1.0 ('));
    });
  });

  group('ContactChangeController', () {
    late _MockRepository repository;
    late ProviderContainer container;

    ProviderContainer makeContainer() => ProviderContainer(
          overrides: [accountSecurityRepositoryProvider.overrideWithValue(repository)],
        );

    ContactChangeState state(ContactKind kind) =>
        container.read(contactChangeControllerProvider(kind));

    ContactChangeController controller(ContactKind kind) =>
        container.read(contactChangeControllerProvider(kind).notifier);

    setUp(() {
      repository = _MockRepository();
      container = makeContainer();
      addTearDown(container.dispose);
    });

    test('an invalid number is not sent', () async {
      final notifier = controller(ContactKind.mobile)..setValue('12345');

      expect(await notifier.sendCode(), isFalse);

      expect(state(ContactKind.mobile).showInvalid, isTrue);
      expect(state(ContactKind.mobile).step, ContactChangeStep.entry);
      verifyNever(() => repository.startChange(any(), any()));
    });

    test('an invalid email is not sent', () async {
      final notifier = controller(ContactKind.email)..setValue('nope');

      expect(await notifier.sendCode(), isFalse);

      expect(state(ContactKind.email).showInvalid, isTrue);
      verifyNever(() => repository.startChange(any(), any()));
    });

    test('a valid value moves to the code step with the server lifetime', () async {
      when(() => repository.startChange(ContactKind.mobile, '9000000061'))
          .thenAnswer((_) async => const OtpSent(expiresInSeconds: 120));
      final notifier = controller(ContactKind.mobile)..setValue('9000000061');

      expect(await notifier.sendCode(), isTrue);

      final current = state(ContactKind.mobile);
      expect(current.step, ContactChangeStep.code);
      expect(current.secondsUntilExpiry, 120);
      expect(current.secondsUntilResend, ContactChangeController.resendCooldownSeconds);
      expect(current.sendCount, 1);
    });

    test('an email is trimmed before it is sent', () async {
      when(() => repository.startChange(ContactKind.email, 'new@example.com'))
          .thenAnswer((_) async => const OtpSent());
      final notifier = controller(ContactKind.email)..setValue('  new@example.com ');

      expect(await notifier.sendCode(), isTrue);

      expect(state(ContactKind.email).value, 'new@example.com');
      expect(state(ContactKind.email).secondsUntilExpiry,
          ContactChangeController.defaultExpirySeconds);
    });

    test('a number that belongs to someone else keeps the entry step with the error', () async {
      when(() => repository.startChange(any(), any()))
          .thenThrow(_business('ERROR_MOBILE_ALREADY_REGISTERED'));
      final notifier = controller(ContactKind.mobile)..setValue('9000000062');

      expect(await notifier.sendCode(), isFalse);

      expect(state(ContactKind.mobile).step, ContactChangeStep.entry);
      expect(state(ContactKind.mobile).error?.code, 'ERROR_MOBILE_ALREADY_REGISTERED');
      expect(state(ContactKind.mobile).isBusy, isFalse);
    });

    test('typing again clears the error', () async {
      when(() => repository.startChange(any(), any())).thenThrow(_offline);
      final notifier = controller(ContactKind.mobile)..setValue('9000000062');
      await notifier.sendCode();

      notifier.setValue('9000000063');

      expect(state(ContactKind.mobile).error, isNull);
    });

    test('verify needs a six-digit code', () async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      final notifier = controller(ContactKind.mobile)..setValue('9000000061');
      await notifier.sendCode();
      notifier.setCode('123');

      expect(await notifier.verify(), isFalse);

      expect(state(ContactKind.mobile).showInvalid, isTrue);
      verifyNever(() => repository.confirmChange(any(), any(), any()));
    });

    test('a confirmed code reports success', () async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      when(() => repository.confirmChange(ContactKind.mobile, '9000000061', '123456'))
          .thenAnswer((_) async {});
      final notifier = controller(ContactKind.mobile)..setValue('9000000061');
      await notifier.sendCode();
      notifier.setCode('123456');

      expect(await notifier.verify(), isTrue);

      expect(state(ContactKind.mobile).isBusy, isFalse);
      expect(state(ContactKind.mobile).error, isNull);
    });

    test('a wrong code keeps the step and shows the error', () async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      when(() => repository.confirmChange(any(), any(), any()))
          .thenThrow(_business('ERROR_INVALID_OTP'));
      final notifier = controller(ContactKind.mobile)..setValue('9000000061');
      await notifier.sendCode();
      notifier.setCode('000000');

      expect(await notifier.verify(), isFalse);

      expect(state(ContactKind.mobile).step, ContactChangeStep.code);
      expect(state(ContactKind.mobile).error?.code, 'ERROR_INVALID_OTP');
      expect(state(ContactKind.mobile).canVerify, isTrue);
    });

    test('too many wrong codes lock the step', () async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      when(() => repository.confirmChange(any(), any(), any()))
          .thenThrow(_business('ERROR_OTP_MAX_ATTEMPTS'));
      final notifier = controller(ContactKind.mobile)..setValue('9000000061');
      await notifier.sendCode();
      notifier.setCode('000000');

      await notifier.verify();
      notifier.setCode('111111');

      expect(state(ContactKind.mobile).isLocked, isTrue);
      expect(state(ContactKind.mobile).canVerify, isFalse);
      expect(await notifier.verify(), isFalse);
      verify(() => repository.confirmChange(any(), any(), any())).called(1);
    });

    test('editing the value returns to the entry step and drops the code', () async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      final notifier = controller(ContactKind.mobile)..setValue('9000000061');
      await notifier.sendCode();
      notifier.setCode('123456');

      notifier.editValue();

      expect(state(ContactKind.mobile).step, ContactChangeStep.entry);
      expect(state(ContactKind.mobile).code, isEmpty);
      expect(state(ContactKind.mobile).value, '9000000061');
    });

    testWidgets('resend sends again, restarts the countdown and stops at the limit',
        (tester) async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      final local = makeContainer();
      final provider = contactChangeControllerProvider(ContactKind.mobile);
      local.listen(provider, (_, __) {});
      final notifier = local.read(provider.notifier)..setValue('9000000061');
      await notifier.sendCode();
      expect(local.read(provider).canResend, isFalse);

      for (var send = 2; send <= ContactChangeController.maxSends; send++) {
        await tester.pump(const Duration(seconds: ContactChangeController.resendCooldownSeconds));
        expect(local.read(provider).canResend, isTrue);
        await notifier.resend();
        expect(local.read(provider).sendCount, send);
        expect(
            local.read(provider).secondsUntilResend, ContactChangeController.resendCooldownSeconds);
      }

      await tester.pump(const Duration(seconds: ContactChangeController.resendCooldownSeconds));
      expect(local.read(provider).canResend, isFalse);
      verify(() => repository.startChange(any(), any())).called(ContactChangeController.maxSends);
      local.dispose();
    });

    testWidgets('the code expires after its lifetime', (tester) async {
      when(() => repository.startChange(any(), any()))
          .thenAnswer((_) async => const OtpSent(expiresInSeconds: 60));
      final local = makeContainer();
      final provider = contactChangeControllerProvider(ContactKind.email);
      local.listen(provider, (_, __) {});
      final notifier = local.read(provider.notifier)..setValue('new@example.com');
      await notifier.sendCode();
      expect(local.read(provider).isExpired, isFalse);

      await tester.pump(const Duration(seconds: 60));

      expect(local.read(provider).isExpired, isTrue);
      expect(local.read(provider).canVerify, isFalse);
      local.dispose();
    });

    test('resend is refused before the cooldown is over', () async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      final notifier = controller(ContactKind.mobile)..setValue('9000000061');
      await notifier.sendCode();

      await notifier.resend();

      expect(state(ContactKind.mobile).sendCount, 1);
      verify(() => repository.startChange(any(), any())).called(1);
    });

    testWidgets('a failed resend keeps the code step and shows the error', (tester) async {
      when(() => repository.startChange(any(), any())).thenAnswer((_) async => const OtpSent());
      final local = makeContainer();
      final provider = contactChangeControllerProvider(ContactKind.mobile);
      local.listen(provider, (_, __) {});
      final notifier = local.read(provider.notifier)..setValue('9000000061');
      await notifier.sendCode();
      await tester.pump(const Duration(seconds: ContactChangeController.resendCooldownSeconds));
      when(() => repository.startChange(any(), any())).thenThrow(_business('ERROR_OTP_RATE_LIMIT'));

      await notifier.resend();

      expect(local.read(provider).step, ContactChangeStep.code);
      expect(local.read(provider).error?.code, 'ERROR_OTP_RATE_LIMIT');
      expect(local.read(provider).isBusy, isFalse);
      local.dispose();
    });
  });

  group('screens', () {
    late AppHarness harness;
    late _MockRepository repository;

    Future<void> launch(
      WidgetTester tester, {
      AccountSecurity summary = _pending,
      List<ActiveSession>? sessions,
    }) async {
      repository = _MockRepository();
      when(() => repository.summary()).thenAnswer((_) async => summary);
      when(() => repository.sessions()).thenAnswer((_) async => sessions ?? [_thisDevice]);
      harness = AppHarness(
        tester,
        extraOverrides: [accountSecurityRepositoryProvider.overrideWithValue(repository)],
      )..signedInAs(AccountStatus.active, aadhaarVerified: summary.aadhaarVerified);
      await harness.launch(location: RouteNames.accountSecurity);
    }

    Finder changeButton(int index) => find.widgetWithText(TextButton, 'Change').at(index);

    Future<void> startMobileChange(WidgetTester tester, {String number = '9000000061'}) async {
      when(() => repository.startChange(ContactKind.mobile, number))
          .thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
      await tester.tap(changeButton(0));
      await harness.settle();
      await tester.enterText(find.byType(TextField), number);
      await tester.tap(find.text('Send code'));
      await harness.settle();
    }

    testWidgets('shows the sign-in details, Aadhaar status and signed-in devices', (tester) async {
      await launch(tester, sessions: [_thisDevice, _otherDevice]);

      expect(find.byType(AccountSecurityScreen), findsOneWidget);
      expect(find.text('Account Security'), findsOneWidget);
      expect(find.text('90XXXX0060'), findsOneWidget);
      expect(find.text('us***@example.com'), findsOneWidget);
      expect(find.text('Not verified yet'), findsOneWidget);
      expect(find.text('Required before your first buy or sell'), findsOneWidget);
      expect(find.text('Active sessions'), findsOneWidget);
      expect(find.text('JustQlic \u00B7 iOS'), findsOneWidget);
      expect(find.text('Mozilla/5.0 (Linux; Android 15)'), findsOneWidget);
      expect(find.text('This device'), findsOneWidget);
      expect(find.textContaining('Last active'), findsNWidgets(2));
      expect(find.text('10.0.0.5'), findsOneWidget);
      expect(find.text('Log out of all other devices'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Delete My Account'), 200);
      expect(find.text('Delete My Account'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a verified Aadhaar shows its status and no action', (tester) async {
      await launch(tester, summary: _verified);

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Verify now'), findsNothing);
      await harness.dispose();
    });

    testWidgets('Verify now opens Aadhaar verification', (tester) async {
      await launch(tester);

      await tester.tap(find.text('Verify now'));
      await harness.settle();

      expect(find.text('Verify Aadhaar'), findsWidgets);
      expect(find.byType(AccountSecurityScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('a session without a name or address is still listed', (tester) async {
      await launch(
        tester,
        sessions: [
          const ActiveSession(id: 'x', deviceInfo: 'Dart/3.9 (dart:io)', isCurrent: true),
        ],
      );

      expect(find.text('Unknown device'), findsOneWidget);
      expect(find.text('This device'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('delete account answers with the coming soon message', (tester) async {
      await launch(tester);

      await tester.scrollUntilVisible(find.text('Delete My Account'), 200);
      await tester.tap(find.text('Delete My Account'));
      await harness.settle();

      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failed summary shows the error and Retry loads it again', (tester) async {
      repository = _MockRepository();
      var calls = 0;
      when(() => repository.summary()).thenAnswer((_) async {
        if (calls++ == 0) throw _offline;
        return _pending;
      });
      when(() => repository.sessions()).thenAnswer((_) async => [_thisDevice]);
      harness = AppHarness(
        tester,
        extraOverrides: [accountSecurityRepositoryProvider.overrideWithValue(repository)],
      )..signedInAs(AccountStatus.active);
      await harness.launch(location: RouteNames.accountSecurity);
      expect(find.text('Unable to connect \u2014 Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('90XXXX0060'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('failed sessions are reported in place and Retry loads them', (tester) async {
      await launch(tester);
      var calls = 0;
      when(() => repository.sessions()).thenAnswer((_) async {
        if (calls++ == 0) throw _offline;
        return [_thisDevice];
      });
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await harness.settle();
      expect(find.text('Unable to load your sessions'), findsOneWidget);
      expect(find.text('90XXXX0060'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('This device'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('with no other device there is nothing to log out', (tester) async {
      await launch(tester);

      expect(find.text('This is the only device signed in'), findsOneWidget);
      expect(find.text('Log out of all other devices'), findsNothing);
      await harness.dispose();
    });

    group('log out of other devices', () {
      testWidgets('asks first and does nothing on cancel', (tester) async {
        await launch(tester, sessions: [_thisDevice, _otherDevice]);

        await tester.tap(find.text('Log out of all other devices'));
        await harness.settle();
        expect(find.text('Log out of other devices?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await harness.settle();

        verifyNever(() => repository.revokeOtherSessions());
        expect(find.text('Log out of other devices?'), findsNothing);
        await harness.dispose();
      });

      testWidgets('confirming revokes them and refreshes the list', (tester) async {
        await launch(tester, sessions: [_thisDevice, _otherDevice]);
        when(() => repository.revokeOtherSessions()).thenAnswer((_) async {
          when(() => repository.sessions()).thenAnswer((_) async => [_thisDevice]);
        });

        await tester.tap(find.text('Log out of all other devices'));
        await harness.settle();
        await tester.tap(find.widgetWithText(TextButton, 'Log out'));
        await harness.settle();

        verify(() => repository.revokeOtherSessions()).called(1);
        expect(find.text('Logged out of 1 other device'), findsOneWidget);
        expect(find.text('Mozilla/5.0 (Linux; Android 15)'), findsNothing);
        expect(find.text('This is the only device signed in'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('another device leaving first is reported and the list refreshed',
          (tester) async {
        await launch(tester, sessions: [_thisDevice, _otherDevice]);
        when(() => repository.revokeOtherSessions()).thenAnswer((_) async {
          when(() => repository.sessions()).thenAnswer((_) async => [_thisDevice]);
          throw _business('ERROR_NO_OTHER_SESSIONS');
        });

        await tester.tap(find.text('Log out of all other devices'));
        await harness.settle();
        await tester.tap(find.widgetWithText(TextButton, 'Log out'));
        await harness.settle();

        expect(find.text('No other active sessions found'), findsOneWidget);
        expect(find.text('This is the only device signed in'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('a network failure is shown under the button', (tester) async {
        await launch(tester, sessions: [_thisDevice, _otherDevice]);
        when(() => repository.revokeOtherSessions()).thenThrow(_offline);

        await tester.tap(find.text('Log out of all other devices'));
        await harness.settle();
        await tester.tap(find.widgetWithText(TextButton, 'Log out'));
        await harness.settle();

        expect(find.text('Unable to connect \u2014 Retry'), findsOneWidget);
        expect(find.text('Mozilla/5.0 (Linux; Android 15)'), findsOneWidget);
        await harness.dispose();
      });
    });

    group('change mobile number', () {
      testWidgets('an invalid number shows an error and sends nothing', (tester) async {
        await launch(tester);

        await tester.tap(changeButton(0));
        await harness.settle();
        expect(find.byType(ChangeContactScreen), findsOneWidget);
        expect(find.text('Your current number stays active until you confirm the new one.'),
            findsOneWidget);
        await tester.enterText(find.byType(TextField), '12345');
        await tester.tap(find.text('Send code'));
        await harness.settle();

        expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
        verifyNever(() => repository.startChange(any(), any()));
        await harness.dispose();
      });

      testWidgets('a number that belongs to another account is rejected', (tester) async {
        await launch(tester);
        when(() => repository.startChange(ContactKind.mobile, '9000000062'))
            .thenThrow(_business('ERROR_MOBILE_ALREADY_REGISTERED'));

        await tester.tap(changeButton(0));
        await harness.settle();
        await tester.enterText(find.byType(TextField), '9000000062');
        await tester.tap(find.text('Send code'));
        await harness.settle();

        expect(find.text('This mobile number is already registered'), findsOneWidget);
        expect(find.text('Confirm new number'), findsNothing);
        await harness.dispose();
      });

      testWidgets('the current number is rejected with a clear message', (tester) async {
        await launch(tester);
        when(() => repository.startChange(ContactKind.mobile, '9000000060'))
            .thenThrow(_business('ERROR_SAME_MOBILE'));

        await tester.tap(changeButton(0));
        await harness.settle();
        await tester.enterText(find.byType(TextField), '9000000060');
        await tester.tap(find.text('Send code'));
        await harness.settle();

        expect(find.text('This is already your mobile number. Enter a different number.'),
            findsOneWidget);
        expect(find.text('Confirm new number'), findsNothing);
        await harness.dispose();
      });

      testWidgets('confirming the code updates the number and returns', (tester) async {
        await launch(tester);
        when(() => repository.confirmChange(ContactKind.mobile, '9000000061', '123456'))
            .thenAnswer((_) async {});

        await startMobileChange(tester);
        expect(find.text('Confirm new number'), findsOneWidget);
        expect(find.text('Enter the 6-digit code sent to +91 9000000061'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '123456');
        await tester.tap(find.text('Verify'));
        await harness.settle();

        verify(() => repository.confirmChange(ContactKind.mobile, '9000000061', '123456'))
            .called(1);
        expect(find.byType(ChangeContactScreen), findsNothing);
        expect(find.byType(AccountSecurityScreen), findsOneWidget);
        expect(find.text('Mobile number updated'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('the summary is read again after a successful change', (tester) async {
        await launch(tester);
        when(() => repository.confirmChange(any(), any(), any())).thenAnswer((_) async {
          when(() => repository.summary()).thenAnswer(
            (_) async => const AccountSecurity(
                mobile: '90XXXX0061', email: 'us***@example.com', aadhaarVerified: false),
          );
        });

        await startMobileChange(tester);
        await tester.enterText(find.byType(TextField), '123456');
        await tester.tap(find.text('Verify'));
        await harness.settle();

        expect(find.text('90XXXX0061'), findsOneWidget);
        expect(find.text('90XXXX0060'), findsNothing);
        await harness.dispose();
      });

      testWidgets('a wrong code shows the error and keeps the step', (tester) async {
        await launch(tester);
        when(() => repository.confirmChange(any(), any(), any()))
            .thenThrow(_business('ERROR_INVALID_OTP'));

        await startMobileChange(tester);
        await tester.enterText(find.byType(TextField), '000000');
        await tester.tap(find.text('Verify'));
        await harness.settle();

        expect(find.text('Invalid or expired OTP'), findsOneWidget);
        expect(find.text('Confirm new number'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('an incomplete code is not sent', (tester) async {
        await launch(tester);

        await startMobileChange(tester);
        await tester.enterText(find.byType(TextField), '123');
        await tester.tap(find.text('Verify'));
        await harness.settle();

        expect(find.text('Enter the 6-digit code'), findsOneWidget);
        verifyNever(() => repository.confirmChange(any(), any(), any()));
        await harness.dispose();
      });

      testWidgets('Change number returns to the entry step with the typed number', (tester) async {
        await launch(tester);

        await startMobileChange(tester);
        await tester.tap(find.text('Change number'));
        await harness.settle();

        expect(find.text('Change mobile number'), findsWidgets);
        expect(find.text('9000000061'), findsOneWidget);
        expect(find.byType(ChangeContactScreen), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('back from the code step returns to the entry step, not the settings',
          (tester) async {
        await launch(tester);

        await startMobileChange(tester);
        await tester.tap(find.byTooltip('Back'));
        await harness.settle();

        expect(find.byType(ChangeContactScreen), findsOneWidget);
        expect(find.text('Send code'), findsOneWidget);

        await tester.tap(find.byTooltip('Back'));
        await harness.settle();

        expect(find.byType(ChangeContactScreen), findsNothing);
        expect(find.byType(AccountSecurityScreen), findsOneWidget);
        verifyNever(() => repository.confirmChange(any(), any(), any()));
        await harness.dispose();
      });

      testWidgets('Resend code sends a new code once the countdown is over', (tester) async {
        await launch(tester);

        await startMobileChange(tester);
        expect(find.textContaining('Resend code in'), findsOneWidget);
        await tester.pump(const Duration(seconds: 31));
        await tester.tap(find.text('Resend code'));
        await harness.settle();

        verify(() => repository.startChange(ContactKind.mobile, '9000000061')).called(2);
        expect(find.text('A new code has been sent'), findsOneWidget);
        await harness.dispose();
      });
    });

    group('change email', () {
      Future<void> startEmailChange(WidgetTester tester, {String email = 'new@example.com'}) async {
        when(() => repository.startChange(ContactKind.email, email))
            .thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
        await tester.tap(changeButton(1));
        await harness.settle();
        await tester.enterText(find.byType(TextField), email);
        await tester.tap(find.text('Send code'));
        await harness.settle();
      }

      testWidgets('an invalid address shows an error and sends nothing', (tester) async {
        await launch(tester);

        await tester.tap(changeButton(1));
        await harness.settle();
        expect(find.text('Your current email stays active until you confirm the new one.'),
            findsOneWidget);
        await tester.enterText(find.byType(TextField), 'not-an-email');
        await tester.tap(find.text('Send code'));
        await harness.settle();

        expect(find.text('Enter a valid email address'), findsOneWidget);
        verifyNever(() => repository.startChange(any(), any()));
        await harness.dispose();
      });

      testWidgets('an address that belongs to another account is rejected', (tester) async {
        await launch(tester);
        when(() => repository.startChange(ContactKind.email, 'taken@example.com'))
            .thenThrow(_business('ERROR_EMAIL_ALREADY_REGISTERED'));

        await tester.tap(changeButton(1));
        await harness.settle();
        await tester.enterText(find.byType(TextField), 'taken@example.com');
        await tester.tap(find.text('Send code'));
        await harness.settle();

        expect(find.text('This email is already linked to another account'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('the current address is rejected with a clear message', (tester) async {
        await launch(tester);
        when(() => repository.startChange(ContactKind.email, 'us@example.com'))
            .thenThrow(_business('ERROR_SAME_EMAIL'));

        await tester.tap(changeButton(1));
        await harness.settle();
        await tester.enterText(find.byType(TextField), 'us@example.com');
        await tester.tap(find.text('Send code'));
        await harness.settle();

        expect(find.text('This is already your email address. Enter a different address.'),
            findsOneWidget);
        await harness.dispose();
      });

      testWidgets('confirming the code updates the email and returns', (tester) async {
        await launch(tester);
        when(() => repository.confirmChange(ContactKind.email, 'new@example.com', '123456'))
            .thenAnswer((_) async {});

        await startEmailChange(tester);
        expect(find.text('Confirm new email'), findsOneWidget);
        expect(find.text('Enter the 6-digit code sent to new@example.com'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '123456');
        await tester.tap(find.text('Verify'));
        await harness.settle();

        expect(find.byType(AccountSecurityScreen), findsOneWidget);
        expect(find.text('Email updated'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('an expired code can be replaced by asking for a new one', (tester) async {
        await launch(tester);
        when(() => repository.confirmChange(any(), any(), any()))
            .thenThrow(_business('ERROR_OTP_EXPIRED'));

        await startEmailChange(tester);
        await tester.enterText(find.byType(TextField), '123456');
        await tester.tap(find.text('Verify'));
        await harness.settle();

        expect(find.text('OTP has expired. Please request a new one'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('the send limit is explained', (tester) async {
        await launch(tester);
        when(() => repository.startChange(any(), any()))
            .thenThrow(_business('ERROR_OTP_RATE_LIMIT'));

        await tester.tap(changeButton(1));
        await harness.settle();
        await tester.enterText(find.byType(TextField), 'new@example.com');
        await tester.tap(find.text('Send code'));
        await harness.settle();

        expect(find.text('Too many OTP requests. Please try again in 10 minutes'), findsOneWidget);
        await harness.dispose();
      });
    });

    testWidgets('settings and both change steps meet accessibility guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await launch(tester, sessions: [_thisDevice, _otherDevice]);

      Future<void> checkGuidelines() async {
        for (final guideline in [
          androidTapTargetGuideline,
          labeledTapTargetGuideline,
          textContrast,
        ]) {
          await expectLater(tester, meetsGuideline(guideline));
        }
      }

      await checkGuidelines();
      expect(tester.getSemantics(find.text('Account Security')), isSemantics(isHeader: true));
      expect(find.bySemanticsLabel('Change mobile number'), findsOneWidget);
      expect(find.bySemanticsLabel('Change email'), findsOneWidget);

      await tester.tap(changeButton(0));
      await harness.settle();
      await checkGuidelines();
      expect(tester.getSemantics(find.text('Change mobile number').first),
          isSemantics(isHeader: true));

      when(() => repository.startChange(ContactKind.mobile, '9000000061'))
          .thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
      await tester.enterText(find.byType(TextField), '9000000061');
      await tester.tap(find.text('Send code'));
      await harness.settle();
      expect(find.text('Confirm new number'), findsOneWidget);
      await checkGuidelines();
      semantics.dispose();
      await harness.dispose();
    });

    testWidgets('the settings page at 200% text in Hindi does not overflow', (tester) async {
      await launch(tester, sessions: [_thisDevice, _otherDevice]);
      tester.view.physicalSize = const Size(960, 1920);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.localeTestValue = const Locale('hi');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await harness.settle();

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byType(ProfileSignOutTile), 300);
      expect(tester.takeException(), isNull);
      await harness.dispose();
    });

    testWidgets('the change page at 200% text keeps its action reachable', (tester) async {
      await launch(tester);
      await tester.tap(changeButton(0));
      await harness.settle();
      tester.view.physicalSize = const Size(960, 1920);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.localeTestValue = const Locale('hi');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await harness.settle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      await harness.dispose();
    });
  });
}
