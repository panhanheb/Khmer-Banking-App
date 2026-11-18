import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

final class SettingsLanguageChanged extends SettingsEvent {
  const SettingsLanguageChanged(this.languageCode);

  final String languageCode;

  @override
  List<Object?> get props => [languageCode];
}

final class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

/// Dispatched only after a successful local biometric prompt when enabling.
final class SettingsBiometricChanged extends SettingsEvent {
  const SettingsBiometricChanged(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
