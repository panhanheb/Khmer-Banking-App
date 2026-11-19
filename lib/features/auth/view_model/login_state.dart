import 'package:equatable/equatable.dart';

enum LoginStatus { initial, submitting, success, codeSent, failure }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.verificationId,
    this.phone,
    this.error,
  });

  final LoginStatus status;

  /// Set when [status] is [LoginStatus.codeSent].
  final String? verificationId;
  final String? phone;
  final Object? error;

  @override
  List<Object?> get props => [status, verificationId, phone, error];
}
