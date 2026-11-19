import 'package:dio/dio.dart';

import '../device/device_info_service.dart';

/// Identifies this install to the API (`X-Device-Id`, `X-Device-Name`,
/// `X-Device-Platform`) so it appears in the user's device list and can be
/// revoked.
class DeviceHeadersInterceptor extends Interceptor {
  DeviceHeadersInterceptor(this._deviceInfo);

  final DeviceInfoService _deviceInfo;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final device = await _deviceInfo.describe();
      options.headers['X-Device-Id'] = device.deviceId;
      options.headers['X-Device-Name'] = device.deviceName;
      options.headers['X-Device-Platform'] = device.platform;
    } catch (_) {
      // Device headers are best effort.
    }
    handler.next(options);
  }
}
