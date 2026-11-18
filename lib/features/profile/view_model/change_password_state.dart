import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';

class ChangePasswordState extends Equatable {
  const ChangePasswordState({this.status = LoadStatus.initial, this.error});

  final LoadStatus status;
  final Object? error;

  @override
  List<Object?> get props => [status, error];
}
