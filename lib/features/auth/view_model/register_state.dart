import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';
import '../model/auth_entities.dart';

class RegisterState extends Equatable {
  const RegisterState({
    this.status = LoadStatus.initial,
    this.result,
    this.phone,
    this.error,
  });

  final LoadStatus status;
  final RegistrationResult? result;
  final String? phone;
  final Object? error;

  @override
  List<Object?> get props => [status, result, phone, error];
}
