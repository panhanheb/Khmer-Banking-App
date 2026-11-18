import '../../../../core/network/page_result.dart';
import '../entities/bank_transaction.dart';
import '../entities/transaction_filter.dart';
import '../repositories/transactions_repository.dart';

class GetTransactionsUseCase {
  const GetTransactionsUseCase(this._repository);

  final TransactionsRepository _repository;

  Future<PageResult<BankTransaction>> call({
    int page = 0,
    int size = 20,
    TransactionFilter filter = const TransactionFilter(),
  }) =>
      _repository.getTransactions(page: page, size: size, filter: filter);
}

class GetTransactionUseCase {
  const GetTransactionUseCase(this._repository);

  final TransactionsRepository _repository;

  Future<BankTransaction> call(String id) => _repository.getTransaction(id);
}
