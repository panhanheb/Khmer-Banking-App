import 'package:equatable/equatable.dart';

class TokenPair extends Equatable {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 0,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  /// Access token lifetime in seconds.
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn];
}

/// Result of `POST /auth/login`.
class LoginResult extends Equatable {
  const LoginResult({
    required this.mfaRequired,
    this.tokens,
    this.challengeId,
    this.devOtp,
  });

  final bool mfaRequired;
  final TokenPair? tokens;
  final String? challengeId;

  /// Only returned by the backend `dev` profile.
  final String? devOtp;

  @override
  List<Object?> get props => [mfaRequired, tokens, challengeId, devOtp];
}

/// Result of `POST /auth/register`.
class RegistrationResult extends Equatable {
  const RegistrationResult({
    required this.userId,
    required this.challengeId,
    this.otpExpiresAt,
    this.devOtp,
  });

  final String userId;
  final String challengeId;
  final DateTime? otpExpiresAt;
  final String? devOtp;

  @override
  List<Object?> get props => [userId, challengeId, otpExpiresAt, devOtp];
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.phone,
    required this.email,
    required this.password,
    required this.fullNameEn,
    required this.fullNameKm,
    required this.language,
  });

  final String phone;
  final String email;
  final String password;
  final String fullNameEn;
  final String fullNameKm;
  final String language;

  @override
  List<Object?> get props =>
      [phone, email, password, fullNameEn, fullNameKm, language];
}

/// A device registered to the user (`GET /auth/devices`).
class DeviceSession extends Equatable {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.trusted,
    required this.current,
    this.lastSeenAt,
  });

  final String id;
  final String deviceName;
  final String platform;
  final bool trusted;
  final bool current;
  final DateTime? lastSeenAt;

  @override
  List<Object?> get props =>
      [id, deviceName, platform, trusted, current, lastSeenAt];
}
