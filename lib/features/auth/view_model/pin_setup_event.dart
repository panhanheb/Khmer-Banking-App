import 'package:equatable/equatable.dart';

sealed class PinSetupEvent extends Equatable {
  const PinSetupEvent();

  @override
  List<Object?> get props => [];
}

/// A complete 6-digit PIN was typed for the current step.
final class PinSetupPinEntered extends PinSetupEvent {
  const PinSetupPinEntered(this.pin);

  final String pin;

  @override
  List<Object?> get props => [pin];
}
