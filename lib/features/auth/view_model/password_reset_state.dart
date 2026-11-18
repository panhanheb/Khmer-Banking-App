import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';

enum PasswordResetStep { requestCode, enterCode, done }

class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.step = PasswordResetStep.requestCode,
    this.status = LoadStatus.initial,
    this.phone,
    this.challengeId,
    this.error,
  });

  final PasswordResetStep step;
  final LoadStatus status;
  final String? phone;
  final String? challengeId;
  final Object? error;

  PasswordResetState copyWith({
    PasswordResetStep? step,
    LoadStatus? status,
    String? phone,
    String? challengeId,
    Object? Function()? error,
  }) =>
      PasswordResetState(
        step: step ?? this.step,
        status: status ?? this.status,
        phone: phone ?? this.phone,
        challengeId: challengeId ?? this.challengeId,
        error: error != null ? error() : this.error,
      );

  @override
  List<Object?> get props => [step, status, phone, challengeId, error];
}
