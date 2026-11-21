import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/language/language.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/view_model/auth_bloc.dart';
import '../features/settings/view_model/settings_bloc.dart';
import 'di.dart';
import 'auth_gate.dart';
import 'navigation.dart';
import '../core/widgets/widgets.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Root widget of Khmer Digital Bank.
class KhmerBankApp extends StatefulWidget {
  const KhmerBankApp({super.key});

  @override
  State<KhmerBankApp> createState() => _KhmerBankAppState();
}

class _KhmerBankAppState extends State<KhmerBankApp> {
  late final AuthBloc _authBloc = sl<AuthBloc>()..add(const AuthStarted());
  bool _languageInitialized = false;

  /// Keeps the '.tr' language in sync with the settings.
  void _applyLanguage(String code) {
    if (_languageInitialized) {
      Tr.setLanguage(code);
    } else {
      Tr.init(code);
      _languageInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: sl<SettingsBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;
          final code =
              settings.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode == 'km'
                  ? 'km'
                  : 'en');
          _applyLanguage(code);
          final khmer = code == 'km';
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => 'appName'.tr,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: AppTheme.light(khmer: khmer),
            darkTheme: AppTheme.dark(khmer: khmer),
            themeMode: settings.themeMode,
            locale: Locale(code),
            supportedLocales: Tr.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const AuthGate(),
            builder: (context, child) => BlocListener<AuthBloc, AuthState>(
              listenWhen: (prev, curr) =>
                  curr.sessionExpired && !prev.sessionExpired,
              listener: (context, _) {
                scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: AppLabel('sessionExpired'.tr)),
                );
              },
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
