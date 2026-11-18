import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';
import '../../auth/model/auth_entities.dart';

class DevicesState extends Equatable {
  const DevicesState({
    this.status = LoadStatus.initial,
    this.devices = const [],
    this.revokingId,
    this.revokedId,
    this.error,
  });

  final LoadStatus status;
  final List<DeviceSession> devices;
  final String? revokingId;

  /// Set once after a successful revoke (for a confirmation snackbar).
  final String? revokedId;
  final Object? error;

  @override
  List<Object?> get props => [status, devices, revokingId, revokedId, error];
}
