import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';
import '../model/bank_transaction.dart';

class TransactionDetailState extends Equatable {
  const TransactionDetailState({
    this.status = LoadStatus.initial,
    this.transaction,
    this.error,
  });

  final LoadStatus status;
  final BankTransaction? transaction;
  final Object? error;

  @override
  List<Object?> get props => [status, transaction, error];
}
