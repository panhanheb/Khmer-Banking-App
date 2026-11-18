import '../../../../core/network/page_result.dart';
import '../entities/bank_transaction.dart';
import '../entities/transaction_filter.dart';

abstract class TransactionsRepository {
  Future<PageResult<BankTransaction>> getTransactions({
    int page = 0,
    int size = 20,
    TransactionFilter filter = const TransactionFilter(),
  });

  Future<BankTransaction> getTransaction(String id);
}
