import 'package:equatable/equatable.dart';

import '../../../../core/bloc/load_status.dart';
import '../../domain/entities/account.dart';

class AccountsState extends Equatable {
  const AccountsState({
    this.status = LoadStatus.initial,
    this.accounts = const [],
    this.error,
  });

  final LoadStatus status;
  final List<Account> accounts;
  final Object? error;

  @override
  List<Object?> get props => [status, accounts, error];
}
