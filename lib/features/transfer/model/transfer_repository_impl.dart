import 'transfer_entities.dart';
import 'transfer_repository.dart';
import 'transfer_remote_data_source.dart';

class TransferRepositoryImpl implements TransferRepository {
  const TransferRepositoryImpl(this._remote);

  final TransferRemoteDataSource _remote;

  @override
  Future<Recipient> lookupRecipient(RecipientQuery query) =>
      _remote.lookup(query);

  @override
  Future<TransferQuote> quote(TransferRequest request) =>
      _remote.quote(request);

  @override
  Future<TransferReceipt> submit(
    TransferRequest request, {
    required String pin,
    required String idempotencyKey,
  }) => _remote.submit(request, pin: pin, idempotencyKey: idempotencyKey);
}
