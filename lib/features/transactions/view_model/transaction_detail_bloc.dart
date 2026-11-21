import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../model/bank_transaction.dart';
import '../model/transaction_usecases.dart';
import 'transaction_detail_event.dart';
import 'transaction_detail_state.dart';

export 'transaction_detail_event.dart';
export 'transaction_detail_state.dart';

class TransactionDetailBloc
    extends Bloc<TransactionDetailEvent, TransactionDetailState> {
  TransactionDetailBloc({
    required GetTransactionUseCase getTransaction,
    BankTransaction? initial,
  }) : _getTransaction = getTransaction,
       super(
         TransactionDetailState(
           status: initial == null ? LoadStatus.initial : LoadStatus.success,
           transaction: initial,
         ),
       ) {
    on<TransactionDetailRequested>(_onRequested);
  }

  final GetTransactionUseCase _getTransaction;

  Future<void> _onRequested(
    TransactionDetailRequested event,
    Emitter<TransactionDetailState> emit,
  ) async {
    emit(
      TransactionDetailState(
        status: LoadStatus.loading,
        transaction: state.transaction,
      ),
    );
    try {
      final tx = await _getTransaction(event.id);
      emit(TransactionDetailState(status: LoadStatus.success, transaction: tx));
    } catch (e) {
      emit(
        TransactionDetailState(
          status: state.transaction == null
              ? LoadStatus.failure
              : LoadStatus.success,
          transaction: state.transaction,
          error: e,
        ),
      );
    }
  }
}
