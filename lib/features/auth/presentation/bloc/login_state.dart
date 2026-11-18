import 'package:equatable/equatable.dart';

enum LoginStatus { initial, submitting, success, mfaRequired, failure }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.challengeId,
    this.devOtp,
    this.phone,
    this.error,
  });

  final LoginStatus status;
  final String? challengeId;
  final String? devOtp;
  final String? phone;
  final Object? error;

  @override
  List<Object?> get props => [status, challengeId, devOtp, phone, error];
}
