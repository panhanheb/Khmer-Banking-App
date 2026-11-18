import '../../../core/network/page_result.dart';
import '../../transactions/model/bank_transaction.dart';
import '../../transactions/model/transaction_filter.dart';
import 'account.dart';

abstract class AccountsRepository {
  Future<List<Account>> getAccounts();

  Future<Account> getAccount(String id);

  Future<Account> openAccount(OpenAccountParams params);

  Future<PageResult<BankTransaction>> getAccountTransactions(
    String accountId, {
    int page = 0,
    int size = 20,
    TransactionFilter filter = const TransactionFilter(),
  });
}
