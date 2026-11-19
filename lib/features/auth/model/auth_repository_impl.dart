import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import 'auth_entities.dart';
import 'auth_remote_data_source.dart';
import 'auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication and the bank API.
///
/// * Email + password is the primary sign-in.
/// * The phone number given at registration is verified by SMS and linked to
///   the same Firebase user, so it can also be used to sign in.
/// * The API trusts the Firebase ID token and creates the customer record on
///   the first call; the transaction PIN and devices live on the API.
/// * Firebase errors are translated to [ApiException] codes so the existing
///   `localizedError` mapping keeps working.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required AuthRemoteDataSource remote,
  }) : _auth = auth,
       _remote = remote;

  final FirebaseAuth _auth;
  final AuthRemoteDataSource _remote;

  @override
  Future<PhoneCodeResult> register(RegisterParams params) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
    final user = credential.user!;
    try {
      await user.updateDisplayName(params.fullNameEn);
      final result = await _sendCode(
        params.phone,
        onAutoVerified: user.linkWithCredential,
      );
      unawaited(user.sendEmailVerification().catchError((_) {}));
      return result;
    } catch (_) {
      // Keep registration atomic: without a verified phone the account is
      // removed so the user can simply try again.
      await user.delete().catchError((_) {});
      rethrow;
    }
  });

  @override
  Future<void> verifyRegistrationCode({
    required String verificationId,
    required String code,
  }) => _guard(() async {
    final user = _requireUser();
    await user.linkWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      ),
    );
    unawaited(user.sendEmailVerification().catchError((_) {}));
  });

  @override
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<PhoneCodeResult> sendPhoneLoginCode({required String phone}) => _guard(
    () => _sendCode(phone, onAutoVerified: _auth.signInWithCredential),
  );

  @override
  Future<void> verifyPhoneLoginCode({
    required String verificationId,
    required String code,
  }) => _guard(
    () => _auth.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      ),
    ),
  );

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    final user = _requireUser();
    final email = user.email;
    if (email == null) throw const ApiException(code: ApiException.forbidden);
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: currentPassword),
    );
    await user.updatePassword(newPassword);
  });

  /// Stored BCrypt-hashed on the API, which verifies it for every transfer.
  @override
  Future<void> setPin({String? currentPin, required String newPin}) =>
      _remote.setPin(currentPin: currentPin, newPin: newPin);

  @override
  Future<List<DeviceSession>> getDevices() => _remote.getDevices();

  /// The revoked device is refused by the API until the user signs in on it
  /// again.
  @override
  Future<void> revokeDevice(String id) => _remote.revokeDevice(id);

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<bool> hasSession() async {
    // Wait until Firebase has restored the persisted user.
    await _auth.authStateChanges().first;
    return _auth.currentUser != null;
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async =>
      _auth.currentUser?.getIdToken(forceRefresh);

  // ---------------------------------------------------------------------------

  User _requireUser() =>
      _auth.currentUser ??
      (throw const ApiException(code: ApiException.tokenExpired));

  /// Starts SMS verification. Completes with the verification id once the code
  /// is sent, or after [onAutoVerified] ran when Android verified the number
  /// by itself.
  Future<PhoneCodeResult> _sendCode(
    String phone, {
    required Future<UserCredential> Function(PhoneAuthCredential)
    onAutoVerified,
  }) {
    final completer = Completer<PhoneCodeResult>();
    _auth
        .verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (credential) async {
            // After `codeSent` the user is already on the code screen and can
            // still type the code, so a late auto-verification is ignored.
            if (completer.isCompleted) return;
            try {
              await onAutoVerified(credential);
              completer.complete(const PhoneCodeResult.autoVerified());
            } catch (e, s) {
              if (!completer.isCompleted) completer.completeError(e, s);
            }
          },
          verificationFailed: (e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
          codeSent: (verificationId, _) {
            if (!completer.isCompleted) {
              completer.complete(PhoneCodeResult.codeSent(verificationId));
            }
          },
          codeAutoRetrievalTimeout: (_) {},
        )
        .catchError((Object e, StackTrace s) {
          if (!completer.isCompleted) completer.completeError(e, s);
        });
    return completer.future;
  }

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseAuthException catch (e) {
      throw _toApiException(e);
    }
  }

  static ApiException _toApiException(FirebaseAuthException e) {
    final code = switch (e.code) {
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' => ApiException.invalidCredentials,
      'user-disabled' => ApiException.accountLocked,
      'too-many-requests' || 'quota-exceeded' => ApiException.rateLimited,
      'network-request-failed' => ApiException.networkError,
      'email-already-in-use' => ApiException.emailAlreadyRegistered,
      'credential-already-in-use' ||
      'provider-already-linked' ||
      'phone-number-already-exists' => ApiException.phoneAlreadyRegistered,
      'invalid-verification-code' ||
      'invalid-verification-id' => ApiException.invalidOtp,
      'session-expired' || 'code-expired' => ApiException.otpExpired,
      'weak-password' || 'invalid-phone-number' => ApiException.validationError,
      'requires-recent-login' ||
      'user-token-expired' => ApiException.tokenExpired,
      _ => ApiException.unknown,
    };
    if (code == ApiException.unknown) {
      // e.g. `operation-not-allowed`: the sign-in provider is not enabled in
      // the Firebase console, or SMS needs billing (Blaze plan).
      debugPrint('FirebaseAuthException(${e.code}): ${e.message}');
    }
    return ApiException(code: code, detail: e.message);
  }
}
