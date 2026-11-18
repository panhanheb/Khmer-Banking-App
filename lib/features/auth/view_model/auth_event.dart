import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App launch: decide the initial route from stored tokens.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Tokens were just issued (login / MFA).
final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn();
}

/// Local biometric unlock succeeded.
final class AuthUnlocked extends AuthEvent {
  const AuthUnlocked();
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// The refresh token was rejected by the server.
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
