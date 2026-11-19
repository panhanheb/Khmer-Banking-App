import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App launch: decide the initial route from the restored Firebase user.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// The user just signed in (email, phone code or registration).
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

/// The signed-in user is gone (signed out, disabled or deleted).
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
