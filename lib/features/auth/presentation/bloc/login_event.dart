import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.phone, required this.password});

  /// E.164 phone (+855…).
  final String phone;
  final String password;

  @override
  List<Object?> get props => [phone];
}

final class LoginReset extends LoginEvent {
  const LoginReset();
}
