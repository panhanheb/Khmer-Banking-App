import '../../../../core/device/device_info_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
    required DeviceInfoService deviceInfo,
  })  : _remote = remote,
        _tokens = tokenStorage,
        _deviceInfo = deviceInfo;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;
  final DeviceInfoService _deviceInfo;

  @override
  Future<RegistrationResult> register(RegisterParams params) =>
      _remote.register(RegisterRequestModel(params));

  @override
  Future<void> verifyOtp({required String challengeId, required String code}) =>
      _remote.verifyOtp(challengeId, code);

  @override
  Future<LoginResult> login({
    required String phone,
    required String password,
  }) async {
    final device = await _deviceInfo.describe();
    final result = await _remote.login(
      phone: phone,
      password: password,
      device: device,
    );
    final tokens = result.tokens;
    if (!result.mfaRequired && tokens != null) {
      await _tokens.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    }
    return result;
  }

  @override
  Future<void> verifyLoginMfa({
    required String challengeId,
    required String code,
  }) async {
    final device = await _deviceInfo.describe();
    final tokens = await _remote.loginMfa(
      challengeId: challengeId,
      code: code,
      device: device,
    );
    await _tokens.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  @override
  Future<String> forgotPassword({required String phone}) =>
      _remote.forgotPassword(phone);

  @override
  Future<void> resetPassword({
    required String challengeId,
    required String code,
    required String newPassword,
  }) =>
      _remote.resetPassword(
        challengeId: challengeId,
        code: code,
        newPassword: newPassword,
      );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _remote.changePassword(currentPassword, newPassword);

  @override
  Future<void> setPin({String? currentPin, required String newPin}) =>
      _remote.setPin(currentPin: currentPin, newPin: newPin);

  @override
  Future<List<DeviceSession>> getDevices() => _remote.getDevices();

  @override
  Future<void> revokeDevice(String id) => _remote.revokeDevice(id);

  @override
  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    try {
      if (refresh != null) await _remote.logout(refresh);
    } on ApiException {
      // Best effort: local tokens are wiped regardless.
    } finally {
      await _tokens.clearTokens();
    }
  }

  @override
  Future<bool> hasSession() => _tokens.hasSession();
}
