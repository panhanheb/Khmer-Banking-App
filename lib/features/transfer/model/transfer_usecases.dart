import '../entities/transfer_entities.dart';
import '../repositories/transfer_repository.dart';

class LookupRecipientUseCase {
  const LookupRecipientUseCase(this._repository);

  final TransferRepository _repository;

  Future<Recipient> call(RecipientQuery query) =>
      _repository.lookupRecipient(query);
}

class GetTransferQuoteUseCase {
  const GetTransferQuoteUseCase(this._repository);

  final TransferRepository _repository;

  Future<TransferQuote> call(TransferRequest request) =>
      _repository.quote(request);
}

class SubmitTransferUseCase {
  const SubmitTransferUseCase(this._repository);

  final TransferRepository _repository;

  Future<TransferReceipt> call(
    TransferRequest request, {
    required String pin,
    required String idempotencyKey,
  }) =>
      _repository.submit(request, pin: pin, idempotencyKey: idempotencyKey);
}
