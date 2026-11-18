import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

/// What the backend needs to identify the device on login.
class DeviceDescriptor extends Equatable {
  const DeviceDescriptor({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  final String deviceId;
  final String deviceName;

  /// `ANDROID`, `IOS`, `WEB` or `OTHER`.
  final String platform;

  @override
  List<Object?> get props => [deviceId, deviceName, platform];
}

class DeviceInfoService {
  DeviceInfoService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  DeviceDescriptor? _cached;

  Future<DeviceDescriptor> describe() async {
    final cached = _cached;
    if (cached != null) return cached;
    final id = await _tokenStorage.getOrCreateDeviceId();
    return _cached = DeviceDescriptor(
      deviceId: id,
      deviceName: _deviceName(),
      platform: _platform(),
    );
  }

  static String _platform() {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        return 'OTHER';
    }
  }

  static String _deviceName() {
    if (kIsWeb) return 'Web browser';
    try {
      final os = switch (defaultTargetPlatform) {
        TargetPlatform.android => 'Android',
        TargetPlatform.iOS => 'iPhone',
        TargetPlatform.macOS => 'Mac',
        TargetPlatform.windows => 'Windows PC',
        TargetPlatform.linux => 'Linux PC',
        TargetPlatform.fuchsia => 'Fuchsia',
      };
      final host = Platform.localHostname;
      return host.isEmpty ? os : '$os ($host)';
    } catch (_) {
      return 'Mobile device';
    }
  }
}
