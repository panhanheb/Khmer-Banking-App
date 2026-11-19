import 'auth_entities.dart';

/// Authentication & session contract (backed by Firebase Authentication).
abstract class AuthRepository {
  /// Creates an email/password account, then sends an SMS code to
  /// [RegisterParams.phone] so the number can be linked to the account.
  Future<PhoneCodeResult> register(RegisterParams params);

  /// Links the verified phone number to the newly registered account.
  Future<void> verifyRegistrationCode({
    required String verificationId,
    required String code,
  });

  Future<void> loginWithEmail({
    required String email,
    required String password,
  });

  /// Sends a sign-in SMS code to [phone] (E.164).
  Future<PhoneCodeResult> sendPhoneLoginCode({required String phone});

  /// Completes a phone sign-in with the SMS code.
  Future<void> verifyPhoneLoginCode({
    required String verificationId,
    required String code,
  });

  /// Emails a password reset link.
  Future<void> sendPasswordResetEmail({required String email});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> setPin({String? currentPin, required String newPin});

  Future<List<DeviceSession>> getDevices();

  Future<void> revokeDevice(String id);

  Future<void> logout();

  Future<bool> hasSession();

  /// Firebase ID token for authenticating API calls (`null` when signed out).
  Future<String?> idToken({bool forceRefresh = false});
}
