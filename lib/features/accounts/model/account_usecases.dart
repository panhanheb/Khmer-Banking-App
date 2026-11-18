import '../../../../core/network/page_result.dart';
import '../../../transactions/domain/entities/bank_transaction.dart';
import '../../../transactions/domain/entities/transaction_filter.dart';
import '../entities/account.dart';
import '../repositories/accounts_repository.dart';

class GetAccountsUseCase {
  const GetAccountsUseCase(this._repository);

  final AccountsRepository _repository;

  Future<List<Account>> call() => _repository.getAccounts();
}

class GetAccountUseCase {
  const GetAccountUseCase(this._repository);

  final AccountsRepository _repository;

  Future<Account> call(String id) => _repository.getAccount(id);
}

class OpenAccountUseCase {
  const OpenAccountUseCase(this._repository);

  final AccountsRepository _repository;

  Future<Account> call(OpenAccountParams params) =>
      _repository.openAccount(params);
}

class GetAccountTransactionsUseCase {
  const GetAccountTransactionsUseCase(this._repository);

  final AccountsRepository _repository;

  Future<PageResult<BankTransaction>> call(
    String accountId, {
    int page = 0,
    int size = 20,
    TransactionFilter filter = const TransactionFilter(),
  }) =>
      _repository.getAccountTransactions(
        accountId,
        page: page,
        size: size,
        filter: filter,
      );
}
