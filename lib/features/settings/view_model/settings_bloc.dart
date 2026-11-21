import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/app_settings.dart';
import '../model/settings_usecases.dart';
import 'settings_event.dart';
import 'settings_state.dart';

export 'settings_event.dart';
export 'settings_state.dart';

/// App-wide preferences: language, theme and biometric quick unlock.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required LoadSettingsUseCase loadSettings,
    required UpdateLanguageUseCase updateLanguage,
    required UpdateThemeModeUseCase updateTheme,
    required UpdateBiometricUseCase updateBiometric,
    AppSettings initial = const AppSettings(),
  }) : _load = loadSettings,
       _updateLanguage = updateLanguage,
       _updateTheme = updateTheme,
       _updateBiometric = updateBiometric,
       super(SettingsState(settings: initial)) {
    on<SettingsLoaded>(_onLoaded);
    on<SettingsLanguageChanged>(_onLanguage);
    on<SettingsThemeChanged>(_onTheme);
    on<SettingsBiometricChanged>(_onBiometric);
  }

  final LoadSettingsUseCase _load;
  final UpdateLanguageUseCase _updateLanguage;
  final UpdateThemeModeUseCase _updateTheme;
  final UpdateBiometricUseCase _updateBiometric;

  Future<void> _onLoaded(SettingsLoaded e, Emitter<SettingsState> emit) async {
    emit(SettingsState(settings: await _load()));
  }

  Future<void> _onLanguage(
    SettingsLanguageChanged e,
    Emitter<SettingsState> emit,
  ) async {
    emit(
      SettingsState(
        settings: state.settings.copyWith(languageCode: e.languageCode),
      ),
    );
    await _updateLanguage(e.languageCode);
  }

  Future<void> _onTheme(
    SettingsThemeChanged e,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsState(settings: state.settings.copyWith(themeMode: e.mode)));
    await _updateTheme(e.mode);
  }

  Future<void> _onBiometric(
    SettingsBiometricChanged e,
    Emitter<SettingsState> emit,
  ) async {
    emit(
      SettingsState(
        settings: state.settings.copyWith(biometricEnabled: e.enabled),
      ),
    );
    await _updateBiometric(e.enabled);
  }
}
