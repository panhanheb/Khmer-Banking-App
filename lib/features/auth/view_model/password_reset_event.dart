import 'package:equatable/equatable.dart';

sealed class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();

  @override
  List<Object?> get props => [];
}

final class PasswordResetRequested extends PasswordResetEvent {
  const PasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
