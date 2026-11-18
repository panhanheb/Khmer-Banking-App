import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../model/credential_usecases.dart';
import 'pin_setup_event.dart';
import 'pin_setup_state.dart';

export 'pin_setup_event.dart';
export 'pin_setup_state.dart';

/// Set or change the 6-digit transaction PIN (`PUT /auth/pin`).
class PinSetupBloc extends Bloc<PinSetupEvent, PinSetupState> {
  PinSetupBloc({required PinSetupMode mode, required SetPinUseCase setPin})
      : _setPin = setPin,
        super(PinSetupState.initial(mode)) {
    on<PinSetupPinEntered>(_onPinEntered);
  }

  final SetPinUseCase _setPin;

  Future<void> _onPinEntered(
    PinSetupPinEntered event,
    Emitter<PinSetupState> emit,
  ) async {
    if (state.status.isLoading) return;
    final s = state;
    final next = s.attempt + 1;
    switch (s.step) {
      case PinSetupStep.current:
        emit(PinSetupState(
          mode: s.mode,
          step: PinSetupStep.enterNew,
          currentPin: event.pin,
          attempt: next,
        ));
      case PinSetupStep.enterNew:
        if (Validators.isWeakPin(event.pin)) {
          emit(PinSetupState(
            mode: s.mode,
            step: PinSetupStep.enterNew,
            currentPin: s.currentPin,
            localError: PinLocalError.weak,
            attempt: next,
          ));
          return;
        }
        emit(PinSetupState(
          mode: s.mode,
          step: PinSetupStep.confirm,
          currentPin: s.currentPin,
          newPin: event.pin,
          attempt: next,
        ));
      case PinSetupStep.confirm:
        if (event.pin != s.newPin) {
          emit(PinSetupState(
            mode: s.mode,
            step: PinSetupStep.enterNew,
            currentPin: s.currentPin,
            localError: PinLocalError.mismatch,
            attempt: next,
          ));
          return;
        }
        emit(PinSetupState(
          mode: s.mode,
          step: PinSetupStep.confirm,
          currentPin: s.currentPin,
          newPin: s.newPin,
          status: LoadStatus.loading,
          attempt: s.attempt,
        ));
        try {
          await _setPin(currentPin: s.currentPin, newPin: event.pin);
          emit(PinSetupState(
            mode: s.mode,
            step: PinSetupStep.confirm,
            status: LoadStatus.success,
            attempt: next,
          ));
        } catch (e) {
          final wrongCurrent = e is ApiException &&
              e.code == ApiException.invalidPin &&
              s.mode == PinSetupMode.change;
          emit(PinSetupState(
            mode: s.mode,
            step: wrongCurrent ? PinSetupStep.current : PinSetupStep.enterNew,
            currentPin: wrongCurrent ? null : s.currentPin,
            status: LoadStatus.failure,
            error: e,
            attempt: next,
          ));
        }
    }
  }
}
