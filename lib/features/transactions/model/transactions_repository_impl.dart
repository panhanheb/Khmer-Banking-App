import '../../../core/network/page_result.dart';
import 'bank_transaction.dart';
import 'transaction_filter.dart';
import 'transactions_repository.dart';
import 'transactions_remote_data_source.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  const TransactionsRepositoryImpl(this._remote);

  final TransactionsRemoteDataSource _remote;

  @override
  Future<PageResult<BankTransaction>> getTransactions({
    int page = 0,
    int size = 20,
    TransactionFilter filter = const TransactionFilter(),
  }) =>
      _remote.getTransactions(page: page, size: size, filter: filter);

  @override
  Future<BankTransaction> getTransaction(String id) =>
      _remote.getTransaction(id);
}
