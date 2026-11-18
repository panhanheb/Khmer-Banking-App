import 'package:flutter/material.dart' show ThemeMode;

import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class LoadSettingsUseCase {
  const LoadSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<AppSettings> call() => _repository.load();
}

class UpdateLanguageUseCase {
  const UpdateLanguageUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(String languageCode) =>
      _repository.saveLanguage(languageCode);
}

class UpdateThemeModeUseCase {
  const UpdateThemeModeUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(ThemeMode mode) => _repository.saveThemeMode(mode);
}

class UpdateBiometricUseCase {
  const UpdateBiometricUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(bool enabled) => _repository.saveBiometricEnabled(enabled);
}
