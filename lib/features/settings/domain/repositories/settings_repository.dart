import 'package:flutter/material.dart' show ThemeMode;

import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> saveLanguage(String languageCode);
  Future<void> saveThemeMode(ThemeMode mode);
  Future<void> saveBiometricEnabled(bool enabled);
}
