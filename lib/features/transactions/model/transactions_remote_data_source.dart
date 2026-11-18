import '../../../core/network/api_client.dart';
import '../../../core/network/page_result.dart';
import 'transaction_filter.dart';
import 'bank_transaction_model.dart';

class TransactionsRemoteDataSource {
  const TransactionsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<PageResult<BankTransactionModel>> getTransactions({
    required int page,
    required int size,
    required TransactionFilter filter,
  }) async {
    final data = await _client.get(
      '/transactions',
      query: {'page': page, 'size': size, ...filter.toQuery()},
    );
    return PageResult.fromJson(asJsonMap(data), BankTransactionModel.fromJson);
  }

  Future<BankTransactionModel> getTransaction(String id) async {
    final data = await _client.get('/transactions/$id');
    return BankTransactionModel.fromJson(asJsonMap(data));
  }
}
