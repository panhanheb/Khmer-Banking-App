import '../../../../core/network/api_client.dart';
import '../../domain/entities/transfer_entities.dart';
import '../models/transfer_models.dart';

class TransferRemoteDataSource {
  const TransferRemoteDataSource(this._client);

  final ApiClient _client;

  Future<RecipientModel> lookup(RecipientQuery query) async {
    final data = await _client.post('/transfers/lookup', data: query.toJson());
    return RecipientModel.fromJson(asJsonMap(data));
  }

  Future<TransferQuoteModel> quote(TransferRequest request) async {
    final data = await _client.post(
      '/transfers/quote',
      data: request.toQuoteJson(),
    );
    return TransferQuoteModel.fromJson(asJsonMap(data));
  }

  Future<TransferReceiptModel> submit(
    TransferRequest request, {
    required String pin,
    required String idempotencyKey,
  }) async {
    final data = await _client.post(
      '/transfers',
      data: request.toSubmitJson(pin),
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return TransferReceiptModel.fromJson(asJsonMap(data));
  }
}
