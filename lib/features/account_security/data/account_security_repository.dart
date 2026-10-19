import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/otp/otp_provider.dart';
import '../../../core/utils/provider_retry.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/domain/entities/otp_sent.dart';
import '../domain/account_security.dart';

class AccountSecurityRepository {
  final ApiClient _client;
  final OtpProvider _otp;

  AccountSecurityRepository(this._client, [this._otp = const BackendOtpProvider()]);

  Future<AccountSecurity> summary() => _client.get(ApiConstants.accountSecurity, parse: _summary);

  /// Sends a code to the new value; the current one stays active until it is confirmed.
  Future<OtpSent> startChange(ContactKind kind, String value) async {
    final model = await _client.post(
      kind == ContactKind.mobile
          ? ApiConstants.mobileChangeInitiate
          : ApiConstants.emailChangeInitiate,
      data: kind == ContactKind.mobile ? {'newMobile': value} : {'newEmail': value},
      parse: MessageResponseModel.fromJson,
    );
    await _otp.send(value);
    return model.toOtpSent();
  }

  Future<void> confirmChange(ContactKind kind, String value, String otp) async {
    final proof = {_otp.credentialKey: await _otp.credential(otp)};
    return _client.post<void>(
      kind == ContactKind.mobile ? ApiConstants.mobileChangeVerify : ApiConstants.emailChangeVerify,
      data: kind == ContactKind.mobile
          ? {'newMobile': value, ...proof}
          : {'newEmail': value, ...proof},
    );
  }

  Future<List<ActiveSession>> sessions() => _client.get(ApiConstants.sessions, parse: _sessions);

  Future<void> revokeOtherSessions() => _client.post<void>(ApiConstants.revokeOtherSessions);

  static AccountSecurity _summary(Object? json) {
    final map = json as Map<String, dynamic>;
    return AccountSecurity(
      mobile: map['mobile'] as String?,
      email: map['email'] as String?,
      aadhaarVerified: map['aadhaarVerified'] == true,
    );
  }

  static List<ActiveSession> _sessions(Object? json) {
    return [
      for (final item in json as List<dynamic>) _session(item as Map<String, dynamic>),
    ];
  }

  // The backend serialises its `isCurrent` field as `current`; both spellings are accepted.
  static ActiveSession _session(Map<String, dynamic> map) => ActiveSession(
        id: map['sessionId'] as String,
        deviceInfo: map['deviceInfo'] as String?,
        ipAddress: map['ipAddress'] as String?,
        lastActiveAt: DateTime.tryParse(map['lastActiveAt'] as String? ?? '')?.toLocal(),
        isCurrent: (map['current'] ?? map['isCurrent']) == true,
      );
}

final accountSecurityRepositoryProvider = Provider<AccountSecurityRepository>(
  (ref) => AccountSecurityRepository(ref.watch(apiClientProvider), ref.watch(otpProviderProvider)),
);

final accountSecurityProvider = FutureProvider.autoDispose<AccountSecurity>(
  (ref) => ref.watch(accountSecurityRepositoryProvider).summary(),
  retry: noAutoRetry,
);

final activeSessionsProvider = FutureProvider.autoDispose<List<ActiveSession>>(
  (ref) => ref.watch(accountSecurityRepositoryProvider).sessions(),
  retry: noAutoRetry,
);
