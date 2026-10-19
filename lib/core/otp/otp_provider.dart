import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import '../config/app_config.dart';
import '../network/api_error.dart';

/// Who sends the one-time code and what the verify request carries as proof.
abstract class OtpProvider {
  /// Verify-request field that carries [credential]'s result.
  String get credentialKey;

  /// Runs after the backend accepted a send request for [identifier] (10-digit mobile or email).
  Future<void> send(String identifier);

  /// Turns the code the user typed into the value the backend verifies.
  Future<String> credential(String code);
}

/// The backend sends the code and checks it, so the typed code is the proof.
class BackendOtpProvider implements OtpProvider {
  const BackendOtpProvider();

  @override
  String get credentialKey => 'otp';

  @override
  Future<void> send(String identifier) async {}

  @override
  Future<String> credential(String code) async => code;
}

typedef WidgetCall = Future<Map<String, dynamic>?> Function(Map<String, dynamic> body);

/// MSG91 OTP widget SDK: the app sends and verifies the code, and the backend gets MSG91's
/// access token as proof.
class Msg91OtpProvider implements OtpProvider {
  final String _countryCode;
  final WidgetCall _sendOtp;
  final WidgetCall _verifyOtp;
  String? _reqId;

  Msg91OtpProvider({
    required String widgetId,
    required String authToken,
    String countryCode = '91',
    WidgetCall? sendOtp,
    WidgetCall? verifyOtp,
  })  : _countryCode = countryCode,
        _sendOtp = sendOtp ?? OTPWidget.sendOTP,
        _verifyOtp = verifyOtp ?? OTPWidget.verifyOTP {
    OTPWidget.initializeWidget(widgetId, authToken);
  }

  @override
  String get credentialKey => 'accessToken';

  @override
  Future<void> send(String identifier) async {
    final target = identifier.contains('@') ? identifier : '$_countryCode$identifier';
    final response = await _call(_sendOtp, {'identifier': target}, _sendFailed);
    _reqId = response['message'] as String?;
  }

  @override
  Future<String> credential(String code) async {
    final reqId = _reqId;
    if (reqId == null) throw _invalidOtp;
    final response = await _call(_verifyOtp, {'reqId': reqId, 'otp': code}, _invalidOtp);
    final token = response['message'];
    if (token is! String || token.isEmpty) throw _invalidOtp;
    return token;
  }

  /// A failed or rejected call becomes [rejected]; no connection or a timeout stays retryable.
  Future<Map<String, dynamic>> _call(
      WidgetCall call, Map<String, dynamic> body, ApiError rejected) async {
    final Map<String, dynamic>? response;
    try {
      response = await call(body);
    } catch (error) {
      if (kDebugMode) debugPrint('MSG91 call failed: $error');
      throw _unreachable;
    }
    if (response == null || response['type'] != 'success') {
      if (kDebugMode) debugPrint('MSG91 rejected the call: ${response?['message']}');
      throw rejected;
    }
    return response;
  }

  static const _invalidOtp = ApiError(
    type: ApiErrorType.business,
    message: 'Invalid or expired OTP',
    code: 'ERROR_INVALID_OTP',
    statusCode: 400,
  );

  static const _sendFailed = ApiError(
    type: ApiErrorType.server,
    message: 'Unable to send the OTP',
    code: 'ERROR_OTP_SEND_FAILED',
  );

  static const _unreachable = ApiError(
    type: ApiErrorType.network,
    message: 'Unable to reach the OTP service',
  );
}

final otpProviderProvider = Provider<OtpProvider>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.useMsg91Otp) return const BackendOtpProvider();
  return Msg91OtpProvider(widgetId: config.msg91WidgetId, authToken: config.msg91AuthToken);
});
