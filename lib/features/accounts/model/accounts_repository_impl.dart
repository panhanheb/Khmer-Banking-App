import '../../../core/network/page_result.dart';
import '../../transactions/model/bank_transaction.dart';
import '../../transactions/model/transaction_filter.dart';
import 'account.dart';
import 'accounts_repository.dart';
import 'accounts_remote_data_source.dart';
import 'account_model.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  const AccountsRepositoryImpl(this._remote);

  final AccountsRemoteDataSource _remote;

  @override
  Future<List<Account>> getAccounts() => _remote.getAccounts();

  @override
  Future<Account> getAccount(String id) => _remote.getAccount(id);

  @override
  Future<Account> openAccount(OpenAccountParams params) =>
      _remote.openAccount(OpenAccountRequestModel(params));

  @override
  Future<PageResult<BankTransaction>> getAccountTransactions(
    String accountId, {
    int page = 0,
    int size = 20,
    TransactionFilter filter = const TransactionFilter(),
  }) => _remote.getAccountTransactions(
    accountId,
    page: page,
    size: size,
    filter: filter,
  );
}
