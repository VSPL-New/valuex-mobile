import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/otp/otp_provider.dart';

Msg91OtpProvider _provider({WidgetCall? sendOtp, WidgetCall? verifyOtp}) => Msg91OtpProvider(
      widgetId: 'widget-1',
      authToken: 'token-1',
      sendOtp: sendOtp ?? (_) async => {'type': 'success', 'message': 'req-1'},
      verifyOtp: verifyOtp ?? (_) async => {'type': 'success', 'message': 'jwt-1'},
    );

void main() {
  group('BackendOtpProvider', () {
    test('sends nothing and uses the typed code as the proof', () async {
      const provider = BackendOtpProvider();

      await provider.send('9876543210');

      expect(provider.credentialKey, 'otp');
      expect(await provider.credential('123456'), '123456');
    });
  });

  group('Msg91OtpProvider', () {
    test('sends to the number with the country code and no plus', () async {
      Map<String, dynamic>? body;
      final provider = _provider(sendOtp: (b) async {
        body = b;
        return {'type': 'success', 'message': 'req-1'};
      });

      await provider.send('9876543210');

      expect(body, {'identifier': '919876543210'});
    });

    test('sends to an email address as typed', () async {
      Map<String, dynamic>? body;
      final provider = _provider(sendOtp: (b) async {
        body = b;
        return {'type': 'success', 'message': 'req-1'};
      });

      await provider.send('a@b.com');

      expect(body, {'identifier': 'a@b.com'});
    });

    test('verifies with the request id of the last send and returns the access token', () async {
      Map<String, dynamic>? body;
      final provider = _provider(verifyOtp: (b) async {
        body = b;
        return {'type': 'success', 'message': 'jwt-1'};
      });
      await provider.send('9876543210');

      final token = await provider.credential('123456');

      expect(provider.credentialKey, 'accessToken');
      expect(token, 'jwt-1');
      expect(body, {'reqId': 'req-1', 'otp': '123456'});
    });

    test('a resend replaces the request id', () async {
      var count = 0;
      Map<String, dynamic>? body;
      final provider = _provider(
        sendOtp: (_) async => {'type': 'success', 'message': 'req-${++count}'},
        verifyOtp: (b) async {
          body = b;
          return {'type': 'success', 'message': 'jwt-1'};
        },
      );
      await provider.send('9876543210');
      await provider.send('9876543210');

      await provider.credential('123456');

      expect(body?['reqId'], 'req-2');
    });

    test('a wrong code is reported as an invalid OTP', () async {
      final provider =
          _provider(verifyOtp: (_) async => {'type': 'error', 'message': 'otp not match'});
      await provider.send('9876543210');

      await expectLater(
        provider.credential('000000'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_INVALID_OTP')),
      );
    });

    test('verifying before any send is reported as an invalid OTP', () async {
      await expectLater(
        _provider().credential('123456'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_INVALID_OTP')),
      );
    });

    test('a rejected send is reported as a failed send', () async {
      final provider = _provider(sendOtp: (_) async => {'type': 'error', 'message': 'bad'});

      await expectLater(
        provider.send('9876543210'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_OTP_SEND_FAILED')),
      );
    });

    test('a network failure is retryable', () async {
      final provider = _provider(sendOtp: (_) async => throw Exception('offline'));

      await expectLater(
        provider.send('9876543210'),
        throwsA(isA<ApiError>().having((e) => e.isRetryable, 'retryable', isTrue)),
      );
    });
  });
}
