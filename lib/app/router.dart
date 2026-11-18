import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/model/account.dart';
import '../features/accounts/view_model/account_detail_bloc.dart';
import '../features/accounts/view_model/accounts_bloc.dart';
import '../features/accounts/view_model/open_account_bloc.dart';
import '../features/accounts/view/account_detail_page.dart';
import '../features/accounts/view/accounts_page.dart';
import '../features/accounts/view/open_account_page.dart';
import '../features/auth/view_model/auth_bloc.dart';
import '../features/auth/view_model/login_bloc.dart';
import '../features/auth/view_model/otp_bloc.dart';
import '../features/auth/view_model/password_reset_bloc.dart';
import '../features/auth/view_model/pin_setup_bloc.dart';
import '../features/auth/view_model/register_bloc.dart';
import '../features/auth/view/forgot_password_page.dart';
import '../features/auth/view/lock_page.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/otp_page.dart';
import '../features/auth/view/register_page.dart';
import '../features/auth/view/set_pin_page.dart';
import '../features/auth/view/splash_page.dart';
import '../features/home/view_model/home_bloc.dart';
import '../features/home/view/home_page.dart';
import '../features/profile/view_model/change_password_bloc.dart';
import '../features/profile/view_model/devices_bloc.dart';
import '../features/profile/view_model/profile_bloc.dart';
import '../features/profile/view/change_password_page.dart';
import '../features/profile/view/devices_page.dart';
import '../features/profile/view/profile_page.dart';
import '../features/transactions/model/bank_transaction.dart';
import '../features/transactions/view_model/transaction_detail_bloc.dart';
import '../features/transactions/view_model/transactions_bloc.dart';
import '../features/transactions/view/transaction_detail_page.dart';
import '../features/transactions/view/transactions_page.dart';
import '../features/transfer/model/transfer_entities.dart';
import '../features/transfer/view_model/transfer_bloc.dart';
import '../features/transfer/view/transfer_page.dart';
import '../features/transfer/view/transfer_receipt_page.dart';
import 'di.dart';
import 'main_shell.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(authBloc.stream),
    redirect: (context, state) => _redirect(authBloc.state, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.lock, builder: (_, _) => const LockPage()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<LoginBloc>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<RegisterBloc>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: Routes.otp,
        redirect: (_, state) => state.extra is OtpArgs ? null : Routes.login,
        builder: (_, state) {
          final args = state.extra! as OtpArgs;
          return BlocProvider(
            create: (_) => sl<OtpBloc>(param1: args),
            child: OtpPage(args: args),
          );
        },
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<PasswordResetBloc>(),
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: Routes.setPin,
        builder: (_, state) {
          final mode = state.extra is PinSetupMode
              ? state.extra! as PinSetupMode
              : PinSetupMode.set;
          return BlocProvider(
            create: (_) => sl<PinSetupBloc>(param1: mode),
            child: SetPinPage(mode: mode),
          );
        },
      ),
      GoRoute(
        path: Routes.accounts,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<AccountsBloc>()..add(const AccountsRequested()),
          child: const AccountsPage(),
        ),
        routes: [
          GoRoute(
            path: 'open',
            builder: (_, _) => BlocProvider(
              create: (_) => sl<OpenAccountBloc>(),
              child: const OpenAccountPage(),
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              final initial =
                  state.extra is Account ? state.extra! as Account : null;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => sl<AccountDetailBloc>(
                      param1: id,
                      param2: initial,
                    )..add(const AccountDetailRequested()),
                  ),
                  BlocProvider(
                    create: (_) =>
                        accountHistoryBloc(id)..add(const TransactionsStarted()),
                  ),
                ],
                child: const AccountDetailPage(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.devices,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<DevicesBloc>()..add(const DevicesRequested()),
          child: const DevicesPage(),
        ),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<ChangePasswordBloc>(),
          child: const ChangePasswordPage(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
                child: const HomePage(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.transactions,
              builder: (_, _) => BlocProvider(
                create: (_) =>
                    sl<TransactionsBloc>()..add(const TransactionsStarted()),
                child: const TransactionsPage(),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, state) {
                    final id = state.pathParameters['id']!;
                    final initial = state.extra is BankTransaction
                        ? state.extra! as BankTransaction
                        : null;
                    return BlocProvider(
                      create: (_) =>
                          sl<TransactionDetailBloc>(param1: initial)
                            ..add(TransactionDetailRequested(id)),
                      child: const TransactionDetailPage(),
                    );
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.transfer,
              builder: (_, state) => BlocProvider(
                create: (_) => sl<TransferBloc>()
                  ..add(TransferStarted(
                    preselectedAccountId: state.uri.queryParameters['from'],
                  )),
                child: TransferPage(
                  preselectedAccountId: state.uri.queryParameters['from'],
                ),
              ),
              routes: [
                GoRoute(
                  path: 'receipt',
                  parentNavigatorKey: rootNavigatorKey,
                  redirect: (_, state) =>
                      state.extra is TransferReceipt ? null : Routes.transfer,
                  builder: (_, state) => TransferReceiptPage(
                    receipt: state.extra! as TransferReceipt,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<ProfileBloc>()..add(const ProfileRequested()),
                child: const ProfilePage(),
              ),
            ),
          ]),
        ],
      ),
    ],
  );
}

String? _redirect(AuthState auth, String location) {
  final isPublic = Routes.public.contains(location);
  switch (auth.status) {
    case AuthStatus.unknown:
      return location == Routes.splash ? null : Routes.splash;
    case AuthStatus.locked:
      return location == Routes.lock ? null : Routes.lock;
    case AuthStatus.unauthenticated:
      return isPublic ? null : Routes.login;
    case AuthStatus.authenticated:
      if (isPublic || location == Routes.splash || location == Routes.lock) {
        return Routes.home;
      }
      return null;
  }
}

/// Bridges a BLoC stream to go_router's `refreshListenable`.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
