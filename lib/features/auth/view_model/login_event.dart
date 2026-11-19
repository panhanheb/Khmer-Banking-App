import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Email + password sign-in.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email];
}

/// Phone sign-in: send the SMS code.
final class LoginPhoneCodeRequested extends LoginEvent {
  const LoginPhoneCodeRequested(this.phone);

  /// E.164 phone (+855…).
  final String phone;

  @override
  List<Object?> get props => [phone];
}

final class LoginReset extends LoginEvent {
  const LoginReset();
}
