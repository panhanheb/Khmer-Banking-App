import 'package:equatable/equatable.dart';

enum AuthStatus {
  /// Still restoring the Firebase session (splash).
  unknown,

  /// Signed in, but biometric quick-unlock is required first.
  locked,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.sessionExpired = false,
  });

  final AuthStatus status;

  /// True when the user was signed out because the session expired.
  final bool sessionExpired;

  @override
  List<Object?> get props => [status, sessionExpired];
}
