import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';

enum PinSetupMode { set, change }

enum PinSetupStep { current, enterNew, confirm }

enum PinLocalError { weak, mismatch }

class PinSetupState extends Equatable {
  const PinSetupState({
    required this.mode,
    required this.step,
    this.currentPin,
    this.newPin,
    this.status = LoadStatus.initial,
    this.localError,
    this.error,
    this.attempt = 0,
  });

  factory PinSetupState.initial(PinSetupMode mode) => PinSetupState(
        mode: mode,
        step: mode == PinSetupMode.change
            ? PinSetupStep.current
            : PinSetupStep.enterNew,
      );

  final PinSetupMode mode;
  final PinSetupStep step;
  final String? currentPin;
  final String? newPin;
  final LoadStatus status;
  final PinLocalError? localError;
  final Object? error;

  /// Incremented on every entry so the UI can clear the keypad.
  final int attempt;

  @override
  List<Object?> get props =>
      [mode, step, currentPin, newPin, status, localError, error, attempt];
}
