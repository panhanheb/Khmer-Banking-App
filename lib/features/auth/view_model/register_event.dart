import 'package:equatable/equatable.dart';

import '../model/auth_entities.dart';

sealed class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

final class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted(this.params);

  final RegisterParams params;

  @override
  List<Object?> get props => [params];
}
