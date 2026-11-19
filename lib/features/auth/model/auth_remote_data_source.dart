import '../../../core/network/api_client.dart';
import 'auth_entities.dart';

/// Backend endpoints that complement Firebase Authentication:
/// the transaction PIN (verified server-side on every transfer) and devices.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<void> setPin({String? currentPin, required String newPin}) async {
    await _client.put(
      '/auth/pin',
      data: {'currentPin': currentPin, 'newPin': newPin},
    );
  }

  Future<List<DeviceSession>> getDevices() async {
    final data = await _client.get('/auth/devices');
    return asJsonList(data).map(_device).toList();
  }

  Future<void> revokeDevice(String id) async {
    await _client.delete('/auth/devices/$id');
  }

  static DeviceSession _device(Map<String, dynamic> json) => DeviceSession(
    id: json['id'] as String,
    deviceName: json['deviceName'] as String? ?? '',
    platform: json['platform'] as String? ?? 'OTHER',
    trusted: json['trusted'] as bool? ?? false,
    current: json['current'] as bool? ?? false,
    lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
  );
}
