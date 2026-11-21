import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../auth/model/credential_usecases.dart';
import 'devices_event.dart';
import 'devices_state.dart';

export 'devices_event.dart';
export 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  DevicesBloc({
    required GetDevicesUseCase getDevices,
    required RevokeDeviceUseCase revokeDevice,
  }) : _getDevices = getDevices,
       _revokeDevice = revokeDevice,
       super(const DevicesState()) {
    on<DevicesRequested>(_onRequested);
    on<DeviceRevokeRequested>(_onRevoke);
  }

  final GetDevicesUseCase _getDevices;
  final RevokeDeviceUseCase _revokeDevice;

  Future<void> _onRequested(
    DevicesRequested event,
    Emitter<DevicesState> emit,
  ) async {
    emit(DevicesState(status: LoadStatus.loading, devices: state.devices));
    try {
      final devices = await _getDevices();
      devices.sort((a, b) {
        if (a.current != b.current) return a.current ? -1 : 1;
        final at = a.lastSeenAt ?? DateTime(1970);
        final bt = b.lastSeenAt ?? DateTime(1970);
        return bt.compareTo(at);
      });
      emit(DevicesState(status: LoadStatus.success, devices: devices));
    } catch (e) {
      emit(
        DevicesState(
          status: LoadStatus.failure,
          devices: state.devices,
          error: e,
        ),
      );
    }
  }

  Future<void> _onRevoke(
    DeviceRevokeRequested event,
    Emitter<DevicesState> emit,
  ) async {
    emit(
      DevicesState(
        status: state.status,
        devices: state.devices,
        revokingId: event.deviceId,
      ),
    );
    try {
      await _revokeDevice(event.deviceId);
      emit(
        DevicesState(
          status: LoadStatus.success,
          devices: state.devices.where((d) => d.id != event.deviceId).toList(),
          revokedId: event.deviceId,
        ),
      );
    } catch (e) {
      emit(
        DevicesState(
          status: LoadStatus.success,
          devices: state.devices,
          error: e,
        ),
      );
    }
  }
}
