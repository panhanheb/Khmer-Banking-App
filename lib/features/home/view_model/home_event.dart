import 'dart:async';

import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// Pull-to-refresh; [completer] resolves when loading finishes.
final class HomeRefreshed extends HomeEvent {
  const HomeRefreshed({this.completer});

  final Completer<void>? completer;

  @override
  List<Object?> get props => [completer];
}

final class HomeBalanceVisibilityToggled extends HomeEvent {
  const HomeBalanceVisibilityToggled();
}
