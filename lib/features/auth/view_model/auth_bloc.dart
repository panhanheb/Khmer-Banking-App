import 'package:flutter_bloc/flutter_bloc.dart';

import '../../settings/model/settings_repository.dart';
import '../model/login_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// Global session state. Drives the root screen (see `AuthGate`).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required CheckSessionUseCase checkSession,
    required LogoutUseCase logout,
    required SettingsRepository settings,
    Duration splashDelay = const Duration(milliseconds: 900),
  }) : _checkSession = checkSession,
       _logout = logout,
       _settings = settings,
       _splashDelay = splashDelay,
       super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>(
      (_, emit) => emit(const AuthState(status: AuthStatus.authenticated)),
    );
    on<AuthUnlocked>(
      (_, emit) => emit(const AuthState(status: AuthStatus.authenticated)),
    );
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onExpired);
  }

  final CheckSessionUseCase _checkSession;
  final LogoutUseCase _logout;
  final SettingsRepository _settings;
  final Duration _splashDelay;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final results = await Future.wait([
      _checkSession(),
      _settings.load().then((s) => s.biometricEnabled),
      Future<void>.delayed(_splashDelay).then((_) => true),
    ]);
    final hasSession = results[0];
    final biometric = results[1];
    if (!hasSession) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } else if (biometric) {
      emit(const AuthState(status: AuthStatus.locked));
    } else {
      emit(const AuthState(status: AuthStatus.authenticated));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.unauthenticated) return;
    // Sign out of Firebase too, otherwise the next launch would restore the
    // session; a fresh sign-in is what re-enables a revoked device.
    await _logout();
    emit(
      const AuthState(status: AuthStatus.unauthenticated, sessionExpired: true),
    );
  }
}
