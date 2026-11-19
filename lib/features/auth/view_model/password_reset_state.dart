import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';

class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.status = LoadStatus.initial,
    this.email,
    this.error,
  });

  final LoadStatus status;

  /// Address the reset link was sent to (set on success).
  final String? email;
  final Object? error;

  @override
  List<Object?> get props => [status, email, error];
}
