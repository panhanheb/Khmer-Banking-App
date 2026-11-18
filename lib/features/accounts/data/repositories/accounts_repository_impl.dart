import '../../../../core/network/page_result.dart';
import '../../../transactions/domain/entities/bank_transaction.dart';
import '../../../transactions/domain/entities/transaction_filter.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../datasources/accounts_remote_data_source.dart';
import '../models/account_model.dart';

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
  }) =>
      _remote.getAccountTransactions(
        accountId,
        page: page,
        size: size,
        filter: filter,
      );
}
