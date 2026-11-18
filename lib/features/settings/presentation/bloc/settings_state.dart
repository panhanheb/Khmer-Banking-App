import 'package:equatable/equatable.dart';

import '../../domain/entities/app_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({this.settings = const AppSettings()});

  final AppSettings settings;

  @override
  List<Object?> get props => [settings];
}
