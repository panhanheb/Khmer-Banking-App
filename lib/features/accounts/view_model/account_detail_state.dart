import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';
import '../model/account.dart';

class AccountDetailState extends Equatable {
  const AccountDetailState({
    this.status = LoadStatus.initial,
    this.account,
    this.error,
  });

  final LoadStatus status;
  final Account? account;
  final Object? error;

  @override
  List<Object?> get props => [status, account, error];
}
