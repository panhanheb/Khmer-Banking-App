import 'package:equatable/equatable.dart';

import '../../domain/entities/account.dart';

sealed class OpenAccountEvent extends Equatable {
  const OpenAccountEvent();

  @override
  List<Object?> get props => [];
}

final class OpenAccountSubmitted extends OpenAccountEvent {
  const OpenAccountSubmitted(this.params);

  final OpenAccountParams params;

  @override
  List<Object?> get props => [params];
}
