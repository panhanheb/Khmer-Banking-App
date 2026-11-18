import 'transfer_entities.dart';

String _str(Object? v, [String fallback = '0']) => v == null ? fallback : '$v';

class RecipientModel extends Recipient {
  const RecipientModel({
    required super.accountNumber,
    required super.accountName,
    required super.currency,
    required super.bankName,
  });

  factory RecipientModel.fromJson(Map<String, dynamic> json) => RecipientModel(
        accountNumber: json['accountNumber'] as String? ?? '',
        accountName: json['accountName'] as String? ?? '',
        currency: json['currency'] as String? ?? 'USD',
        bankName: json['bankName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'accountNumber': accountNumber,
        'accountName': accountName,
        'currency': currency,
        'bankName': bankName,
      };
}

extension RecipientQueryJson on RecipientQuery {
  Map<String, dynamic> toJson() => {
        if (accountNumber != null) 'accountNumber': accountNumber,
        if (phone != null) 'phone': phone,
        if (currency != null) 'currency': currency,
      };
}

extension TransferRequestJson on TransferRequest {
  Map<String, dynamic> toQuoteJson() => {
        'sourceAccountId': sourceAccountId,
        'destinationAccountNumber': destinationAccountNumber,
        'amount': amount,
        'currency': currency,
      };

  Map<String, dynamic> toSubmitJson(String pin) => {
        ...toQuoteJson(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        'pin': pin,
      };
}

class TransferQuoteModel extends TransferQuote {
  const TransferQuoteModel({
    required super.debitAmount,
    required super.debitCurrency,
    required super.creditAmount,
    required super.creditCurrency,
    required super.fee,
    required super.feeCurrency,
    required super.totalDebit,
    required super.destinationName,
    super.exchangeRate,
    super.dailyLimitRemaining,
  });

  factory TransferQuoteModel.fromJson(Map<String, dynamic> json) =>
      TransferQuoteModel(
        debitAmount: _str(json['debitAmount']),
        debitCurrency: json['debitCurrency'] as String? ?? 'USD',
        creditAmount: _str(json['creditAmount']),
        creditCurrency: json['creditCurrency'] as String? ?? 'USD',
        fee: _str(json['fee']),
        feeCurrency: json['feeCurrency'] as String? ??
            json['debitCurrency'] as String? ??
            'USD',
        exchangeRate: json['exchangeRate']?.toString(),
        totalDebit: _str(json['totalDebit']),
        destinationName: json['destinationName'] as String? ?? '',
        dailyLimitRemaining: json['dailyLimitRemaining']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'debitAmount': debitAmount,
        'debitCurrency': debitCurrency,
        'creditAmount': creditAmount,
        'creditCurrency': creditCurrency,
        'fee': fee,
        'feeCurrency': feeCurrency,
        'exchangeRate': exchangeRate,
        'totalDebit': totalDebit,
        'destinationName': destinationName,
        'dailyLimitRemaining': dailyLimitRemaining,
      };
}

class TransferReceiptModel extends TransferReceipt {
  const TransferReceiptModel({
    required super.transactionId,
    required super.reference,
    required super.status,
    required super.debitAmount,
    required super.debitCurrency,
    required super.creditAmount,
    required super.creditCurrency,
    required super.fee,
    required super.sourceAccountNumber,
    required super.destinationAccountNumber,
    required super.destinationName,
    super.exchangeRate,
    super.description,
    super.createdAt,
  });

  factory TransferReceiptModel.fromJson(Map<String, dynamic> json) =>
      TransferReceiptModel(
        transactionId: json['transactionId'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        debitAmount: _str(json['debitAmount']),
        debitCurrency: json['debitCurrency'] as String? ?? 'USD',
        creditAmount: _str(json['creditAmount']),
        creditCurrency: json['creditCurrency'] as String? ?? 'USD',
        fee: _str(json['fee']),
        exchangeRate: json['exchangeRate']?.toString(),
        sourceAccountNumber: json['sourceAccountNumber'] as String? ?? '',
        destinationAccountNumber:
            json['destinationAccountNumber'] as String? ?? '',
        destinationName: json['destinationName'] as String? ?? '',
        description: json['description'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'reference': reference,
        'status': status,
        'debitAmount': debitAmount,
        'debitCurrency': debitCurrency,
        'creditAmount': creditAmount,
        'creditCurrency': creditCurrency,
        'fee': fee,
        'exchangeRate': exchangeRate,
        'sourceAccountNumber': sourceAccountNumber,
        'destinationAccountNumber': destinationAccountNumber,
        'destinationName': destinationName,
        'description': description,
        'createdAt': createdAt?.toUtc().toIso8601String(),
      };
}
