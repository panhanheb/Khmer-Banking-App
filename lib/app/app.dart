import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/view_model/auth_bloc.dart';
import '../features/settings/view_model/settings_bloc.dart';
import 'di.dart';
import 'router.dart';

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
  late final GoRouter _router = createRouter(_authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
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
          final code = settings.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode == 'km'
                  ? 'km'
                  : 'en');
          final khmer = code == 'km';
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.l10n.appName,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: AppTheme.light(khmer: khmer),
            darkTheme: AppTheme.dark(khmer: khmer),
            themeMode: settings.themeMode,
            locale: Locale(code),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: _router,
            builder: (context, child) => BlocListener<AuthBloc, AuthState>(
              listenWhen: (prev, curr) =>
                  curr.sessionExpired && !prev.sessionExpired,
              listener: (context, _) {
                scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text(context.l10n.sessionExpired)),
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
