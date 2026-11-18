import 'package:flutter/material.dart' show ThemeMode;

import '../../../core/storage/key_value_store.dart';
import 'app_settings.dart';
import 'settings_repository.dart';

/// Persists preferences in the (secure) key/value store.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._store);

  static const _languageKey = 'kdb.settings.language';
  static const _themeKey = 'kdb.settings.theme';
  static const _biometricKey = 'kdb.settings.biometric';

  final KeyValueStore _store;

  @override
  Future<AppSettings> load() async {
    final language = await _store.read(_languageKey);
    final theme = await _store.read(_themeKey);
    final biometric = await _store.read(_biometricKey);
    return AppSettings(
      languageCode: (language == 'km' || language == 'en') ? language : null,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      ),
      biometricEnabled: biometric == 'true',
    );
  }

  @override
  Future<void> saveLanguage(String languageCode) =>
      _store.write(_languageKey, languageCode);

  @override
  Future<void> saveThemeMode(ThemeMode mode) =>
      _store.write(_themeKey, mode.name);

  @override
  Future<void> saveBiometricEnabled(bool enabled) =>
      _store.write(_biometricKey, '$enabled');
}
