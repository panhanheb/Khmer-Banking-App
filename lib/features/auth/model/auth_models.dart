import 'auth_entities.dart';

class TokenPairModel extends TokenPair {
  const TokenPairModel({
    required super.accessToken,
    required super.refreshToken,
    super.tokenType,
    super.expiresIn,
  });

  factory TokenPairModel.fromJson(Map<String, dynamic> json) => TokenPairModel(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'expiresIn': expiresIn,
      };
}

class LoginResultModel extends LoginResult {
  const LoginResultModel({
    required super.mfaRequired,
    super.tokens,
    super.challengeId,
    super.devOtp,
  });

  factory LoginResultModel.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'];
    return LoginResultModel(
      mfaRequired: json['mfaRequired'] as bool? ?? false,
      tokens: tokens is Map
          ? TokenPairModel.fromJson(Map<String, dynamic>.from(tokens))
          : null,
      challengeId: json['challengeId'] as String?,
      devOtp: json['devOtp'] as String?,
    );
  }
}

class RegistrationResultModel extends RegistrationResult {
  const RegistrationResultModel({
    required super.userId,
    required super.challengeId,
    super.otpExpiresAt,
    super.devOtp,
  });

  factory RegistrationResultModel.fromJson(Map<String, dynamic> json) =>
      RegistrationResultModel(
        userId: json['userId'] as String,
        challengeId: json['challengeId'] as String,
        otpExpiresAt: DateTime.tryParse(json['otpExpiresAt'] as String? ?? ''),
        devOtp: json['devOtp'] as String?,
      );
}

class RegisterRequestModel {
  const RegisterRequestModel(this.params);

  final RegisterParams params;

  Map<String, dynamic> toJson() => {
        'phone': params.phone,
        'email': params.email,
        'password': params.password,
        'fullNameEn': params.fullNameEn,
        'fullNameKm': params.fullNameKm,
        'language': params.language,
      };
}

class DeviceSessionModel extends DeviceSession {
  const DeviceSessionModel({
    required super.id,
    required super.deviceName,
    required super.platform,
    required super.trusted,
    required super.current,
    super.lastSeenAt,
  });

  factory DeviceSessionModel.fromJson(Map<String, dynamic> json) =>
      DeviceSessionModel(
        id: json['id'] as String,
        deviceName: json['deviceName'] as String? ?? '',
        platform: json['platform'] as String? ?? 'OTHER',
        trusted: json['trusted'] as bool? ?? false,
        current: json['current'] as bool? ?? false,
        lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceName': deviceName,
        'platform': platform,
        'trusted': trusted,
        'current': current,
        'lastSeenAt': lastSeenAt?.toUtc().toIso8601String(),
      };
}
