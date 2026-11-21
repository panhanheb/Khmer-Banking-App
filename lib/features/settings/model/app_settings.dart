import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;

class AppSettings extends Equatable {
  const AppSettings({
    this.languageCode,
    this.themeMode = ThemeMode.system,
    this.biometricEnabled = false,
  });

  /// `km`, `en`, or `null` to follow the device language.
  final String? languageCode;
  final ThemeMode themeMode;

  /// Local-only quick unlock / extra transfer confirmation.
  final bool biometricEnabled;

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    bool? biometricEnabled,
  }) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    themeMode: themeMode ?? this.themeMode,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
  );

  @override
  List<Object?> get props => [languageCode, themeMode, biometricEnabled];
}
