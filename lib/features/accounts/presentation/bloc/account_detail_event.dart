import 'package:equatable/equatable.dart';

sealed class AccountDetailEvent extends Equatable {
  const AccountDetailEvent();

  @override
  List<Object?> get props => [];
}

final class AccountDetailRequested extends AccountDetailEvent {
  const AccountDetailRequested();
}
