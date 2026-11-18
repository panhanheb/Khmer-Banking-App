import '../../../../core/device/device_info_service.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

/// Raw calls to `/auth/**` (docs/API.md).
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<RegistrationResultModel> register(RegisterRequestModel request) async {
    final data = await _client.post(
      '/auth/register',
      data: request.toJson(),
      authenticated: false,
    );
    return RegistrationResultModel.fromJson(asJsonMap(data));
  }

  Future<void> verifyOtp(String challengeId, String code) async {
    await _client.post(
      '/auth/otp/verify',
      data: {'challengeId': challengeId, 'code': code},
      authenticated: false,
    );
  }

  Future<LoginResultModel> login({
    required String phone,
    required String password,
    required DeviceDescriptor device,
  }) async {
    final data = await _client.post(
      '/auth/login',
      data: {
        'phone': phone,
        'password': password,
        'deviceId': device.deviceId,
        'deviceName': device.deviceName,
        'platform': device.platform,
      },
      authenticated: false,
    );
    return LoginResultModel.fromJson(asJsonMap(data));
  }

  Future<TokenPairModel> loginMfa({
    required String challengeId,
    required String code,
    required DeviceDescriptor device,
  }) async {
    final data = await _client.post(
      '/auth/login/mfa',
      data: {
        'challengeId': challengeId,
        'code': code,
        'deviceId': device.deviceId,
        'deviceName': device.deviceName,
        'platform': device.platform,
      },
      authenticated: false,
    );
    return TokenPairModel.fromJson(asJsonMap(data));
  }

  Future<void> logout(String refreshToken) async {
    await _client.post(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      authenticated: false,
    );
  }

  Future<String> forgotPassword(String phone) async {
    final data = await _client.post(
      '/auth/password/forgot',
      data: {'phone': phone},
      authenticated: false,
    );
    return asJsonMap(data)['challengeId'] as String;
  }

  Future<void> resetPassword({
    required String challengeId,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth/password/reset',
      data: {
        'challengeId': challengeId,
        'code': code,
        'newPassword': newPassword,
      },
      authenticated: false,
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _client.put(
      '/auth/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> setPin({String? currentPin, required String newPin}) async {
    await _client.put(
      '/auth/pin',
      data: {'currentPin': currentPin, 'newPin': newPin},
    );
  }

  Future<List<DeviceSessionModel>> getDevices() async {
    final data = await _client.get('/auth/devices');
    return asJsonList(data).map(DeviceSessionModel.fromJson).toList();
  }

  Future<void> revokeDevice(String id) async {
    await _client.delete('/auth/devices/$id');
  }
}
