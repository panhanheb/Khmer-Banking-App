import '../../domain/entities/bank_transaction.dart';

class BankTransactionModel extends BankTransaction {
  const BankTransactionModel({
    required super.id,
    required super.reference,
    required super.type,
    required super.status,
    required super.direction,
    required super.amount,
    required super.fee,
    required super.currency,
    required super.accountId,
    required super.simulated,
    super.description,
    super.counterpartyName,
    super.counterpartyAccount,
    super.createdAt,
  });

  /// Amounts are kept as the exact decimal strings the API sends.
  factory BankTransactionModel.fromJson(Map<String, dynamic> json) =>
      BankTransactionModel(
        id: json['id'] as String,
        reference: json['reference'] as String? ?? '',
        type: json['type'] as String? ?? TransactionType.transfer,
        status: json['status'] as String? ?? TransactionStatus.completed,
        direction: json['direction'] as String? ?? 'DEBIT',
        amount: '${json['amount'] ?? '0'}',
        fee: '${json['fee'] ?? '0'}',
        currency: json['currency'] as String? ?? 'USD',
        description: json['description'] as String?,
        counterpartyName: json['counterpartyName'] as String?,
        counterpartyAccount: json['counterpartyAccount'] as String?,
        accountId: json['accountId'] as String? ?? '',
        simulated: json['simulated'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'type': type,
        'status': status,
        'direction': direction,
        'amount': amount,
        'fee': fee,
        'currency': currency,
        'description': description,
        'counterpartyName': counterpartyName,
        'counterpartyAccount': counterpartyAccount,
        'accountId': accountId,
        'simulated': simulated,
        'createdAt': createdAt?.toUtc().toIso8601String(),
      };
}
