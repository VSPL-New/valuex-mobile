import '../../domain/entities/aadhaar_transaction.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/otp_sent.dart';
import '../../domain/entities/user_profile.dart';

/// `AuthResponse`: tokens plus the account state.
class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String? status;
  final bool aadhaarVerified;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.status,
    required this.aadhaarVerified,
  });

  factory AuthResponseModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return AuthResponseModel(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      userId: map['userId'] as String,
      status: map['status'] as String?,
      aadhaarVerified: map['aadhaarVerified'] as bool? ?? false,
    );
  }

  AuthResult toEntity() {
    return AuthResult(
      session: AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      ),
      status: AccountStatus.fromApi(status),
      aadhaarVerified: aadhaarVerified,
    );
  }
}

/// `UserProfileResponse`.
class UserProfileModel {
  final String userId;
  final String? status;
  final bool aadhaarVerified;
  final String? mobile;
  final String? email;
  final String? displayName;
  final String? avatarId;
  final String? city;

  const UserProfileModel({
    required this.userId,
    required this.status,
    required this.aadhaarVerified,
    this.mobile,
    this.email,
    this.displayName,
    this.avatarId,
    this.city,
  });

  factory UserProfileModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return UserProfileModel(
      userId: map['userId'] as String,
      status: map['status'] as String?,
      aadhaarVerified: map['aadhaarVerified'] as bool? ?? false,
      mobile: map['mobile'] as String?,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      avatarId: map['avatarId'] as String?,
      city: map['city'] as String?,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      userId: userId,
      status: AccountStatus.fromApi(status),
      aadhaarVerified: aadhaarVerified,
      mobile: mobile,
      email: email,
      displayName: displayName,
      avatarId: avatarId,
      city: city,
    );
  }
}

/// `MessageResponse`: confirmation text and the OTP lifetime when one was sent.
class MessageResponseModel {
  final int? otpExpiresInSeconds;

  const MessageResponseModel({this.otpExpiresInSeconds});

  factory MessageResponseModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return MessageResponseModel(
      otpExpiresInSeconds: (map['otpExpiresInSeconds'] as num?)?.toInt(),
    );
  }

  OtpSent toOtpSent() => OtpSent(expiresInSeconds: otpExpiresInSeconds);
}

/// `AadhaarInitiateResponse`.
class AadhaarInitiateModel {
  final String transactionId;

  const AadhaarInitiateModel({required this.transactionId});

  factory AadhaarInitiateModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return AadhaarInitiateModel(transactionId: map['transactionId'] as String);
  }

  AadhaarTransaction toEntity() =>
      AadhaarTransaction(transactionId: transactionId);
}
