import '../entities/transfer_entities.dart';

abstract class TransferRepository {
  Future<Recipient> lookupRecipient(RecipientQuery query);

  Future<TransferQuote> quote(TransferRequest request);

  /// Executes the transfer. [idempotencyKey] MUST be reused when retrying the
  /// same logical transfer so the server never double-debits.
  Future<TransferReceipt> submit(
    TransferRequest request, {
    required String pin,
    required String idempotencyKey,
  });
}
