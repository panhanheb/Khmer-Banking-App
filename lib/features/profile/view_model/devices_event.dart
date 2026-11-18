import 'package:equatable/equatable.dart';

sealed class DevicesEvent extends Equatable {
  const DevicesEvent();

  @override
  List<Object?> get props => [];
}

final class DevicesRequested extends DevicesEvent {
  const DevicesRequested();
}

final class DeviceRevokeRequested extends DevicesEvent {
  const DeviceRevokeRequested(this.deviceId);

  final String deviceId;

  @override
  List<Object?> get props => [deviceId];
}
