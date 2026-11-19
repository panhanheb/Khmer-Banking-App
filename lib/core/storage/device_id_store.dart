import 'package:uuid/uuid.dart';

import 'key_value_store.dart';

/// Stable per-install device id, kept in secure storage.
/// (Session tokens are managed by Firebase Authentication.)
class DeviceIdStore {
  DeviceIdStore(this._store);

  static const _deviceIdKey = 'kdb.deviceId';

  final KeyValueStore _store;

  Future<String> getOrCreateDeviceId() async {
    final existing = await _store.read(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _store.write(_deviceIdKey, id);
    return id;
  }
}
