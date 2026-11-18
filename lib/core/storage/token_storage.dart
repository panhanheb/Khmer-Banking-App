import 'package:uuid/uuid.dart';

import 'key_value_store.dart';

/// Persists the session tokens and a stable per-install device id in secure
/// storage. Values are cached in memory to avoid a keystore hit per request.
class TokenStorage {
  TokenStorage(this._store);

  static const _accessKey = 'kdb.accessToken';
  static const _refreshKey = 'kdb.refreshToken';
  static const _deviceIdKey = 'kdb.deviceId';

  final KeyValueStore _store;

  String? _access;
  String? _refresh;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _access = await _store.read(_accessKey);
    _refresh = await _store.read(_refreshKey);
    _loaded = true;
  }

  Future<String?> readAccessToken() async {
    await _ensureLoaded();
    return _access;
  }

  Future<String?> readRefreshToken() async {
    await _ensureLoaded();
    return _refresh;
  }

  Future<bool> hasSession() async {
    final refresh = await readRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
    _loaded = true;
    await _store.write(_accessKey, accessToken);
    await _store.write(_refreshKey, refreshToken);
  }

  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    await _store.delete(_accessKey);
    await _store.delete(_refreshKey);
  }

  /// Stable install-scoped device id sent on login (device trust / MFA).
  Future<String> getOrCreateDeviceId() async {
    final existing = await _store.read(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _store.write(_deviceIdKey, id);
    return id;
  }
}
