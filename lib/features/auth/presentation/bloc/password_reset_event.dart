import 'package:equatable/equatable.dart';

sealed class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();

  @override
  List<Object?> get props => [];
}

final class PasswordResetCodeRequested extends PasswordResetEvent {
  const PasswordResetCodeRequested(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

final class PasswordResetSubmitted extends PasswordResetEvent {
  const PasswordResetSubmitted({required this.code, required this.newPassword});

  final String code;
  final String newPassword;

  @override
  List<Object?> get props => [code];
}
