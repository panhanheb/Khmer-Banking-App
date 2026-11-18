import 'auth_entities.dart';

/// Authentication & session contract. Implementations persist tokens.
abstract class AuthRepository {
  Future<RegistrationResult> register(RegisterParams params);

  Future<void> verifyOtp({required String challengeId, required String code});

  /// Logs in from this device. When MFA is not required the returned tokens
  /// are already persisted.
  Future<LoginResult> login({required String phone, required String password});

  /// Completes a new-device login; persists the issued tokens.
  Future<void> verifyLoginMfa({
    required String challengeId,
    required String code,
  });

  /// Returns the challenge id for the reset code.
  Future<String> forgotPassword({required String phone});

  Future<void> resetPassword({
    required String challengeId,
    required String code,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> setPin({String? currentPin, required String newPin});

  Future<List<DeviceSession>> getDevices();

  Future<void> revokeDevice(String id);

  /// Revokes the refresh token server-side (best effort) and wipes tokens.
  Future<void> logout();

  Future<bool> hasSession();
}
