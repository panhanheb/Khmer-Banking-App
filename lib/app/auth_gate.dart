import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/view/lock_page.dart';
import '../features/auth/view/splash_page.dart';
import '../features/auth/view_model/auth_bloc.dart';
import 'main_shell.dart';
import 'navigation.dart';
import 'pages.dart';

/// Root screen chosen from the session state:
/// splash → (lock) → main shell, or login when signed out.
///
/// Whenever the state changes (signed in, locked, signed out, session expired)
/// every pushed screen is closed, so e.g. a finished OTP flow or a logout from a
/// sub-page lands on the right root.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (_, state) {
        popToRoot();
        if (state.status == AuthStatus.authenticated) {
          mainTab.value = MainTab.home;
        }
      },
      buildWhen: (a, b) => a.status != b.status,
      builder: (_, state) => KeyedSubtree(
        key: ValueKey(state.status),
        child: switch (state.status) {
          AuthStatus.unknown => const SplashPage(),
          AuthStatus.locked => const LockPage(),
          AuthStatus.unauthenticated => Pages.login(),
          AuthStatus.authenticated => const MainShell(),
        },
      ),
    );
  }
}
