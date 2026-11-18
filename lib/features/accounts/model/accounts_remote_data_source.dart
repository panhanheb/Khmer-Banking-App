import '../../../core/network/api_client.dart';
import '../../../core/network/page_result.dart';
import '../../transactions/model/bank_transaction_model.dart';
import '../../transactions/model/transaction_filter.dart';
import 'account_model.dart';

class AccountsRemoteDataSource {
  const AccountsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<AccountModel>> getAccounts() async {
    final data = await _client.get('/accounts');
    return asJsonList(data).map(AccountModel.fromJson).toList();
  }

  Future<AccountModel> getAccount(String id) async {
    final data = await _client.get('/accounts/$id');
    return AccountModel.fromJson(asJsonMap(data));
  }

  Future<AccountModel> openAccount(OpenAccountRequestModel request) async {
    final data = await _client.post('/accounts', data: request.toJson());
    return AccountModel.fromJson(asJsonMap(data));
  }

  Future<PageResult<BankTransactionModel>> getAccountTransactions(
    String accountId, {
    required int page,
    required int size,
    required TransactionFilter filter,
  }) async {
    final query = filter.toQuery()..remove('currency')..remove('q');
    final data = await _client.get(
      '/accounts/$accountId/transactions',
      query: {'page': page, 'size': size, ...query},
    );
    return PageResult.fromJson(asJsonMap(data), BankTransactionModel.fromJson);
  }
}
