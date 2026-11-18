import 'package:equatable/equatable.dart';

sealed class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

final class OtpSubmitted extends OtpEvent {
  const OtpSubmitted(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
