import '../../../core/network/page_result.dart';
import 'bank_transaction.dart';
import 'transaction_filter.dart';

abstract class TransactionsRepository {
  Future<PageResult<BankTransaction>> getTransactions({
    int page = 0,
    int size = 20,
    TransactionFilter filter = const TransactionFilter(),
  });

  Future<BankTransaction> getTransaction(String id);
}
