import 'package:equatable/equatable.dart';

/// `POST /transfers/lookup` result (name is masked server-side).
class Recipient extends Equatable {
  const Recipient({
    required this.accountNumber,
    required this.accountName,
    required this.currency,
    required this.bankName,
  });

  final String accountNumber;
  final String accountName;
  final String currency;
  final String bankName;

  @override
  List<Object?> get props => [accountNumber, accountName, currency, bankName];
}

/// Lookup by account number OR phone (exactly one is set).
class RecipientQuery extends Equatable {
  const RecipientQuery.byAccountNumber(String this.accountNumber)
    : phone = null,
      currency = null;

  const RecipientQuery.byPhone(String this.phone, {this.currency})
    : accountNumber = null;

  final String? accountNumber;
  final String? phone;

  /// Preferred currency for phone lookups.
  final String? currency;

  @override
  List<Object?> get props => [accountNumber, phone, currency];
}

class TransferRequest extends Equatable {
  const TransferRequest({
    required this.sourceAccountId,
    required this.destinationAccountNumber,
    required this.amount,
    required this.currency,
    this.description,
  });

  final String sourceAccountId;
  final String destinationAccountNumber;

  /// Canonical decimal string in [currency].
  final String amount;
  final String currency;
  final String? description;

  @override
  List<Object?> get props => [
    sourceAccountId,
    destinationAccountNumber,
    amount,
    currency,
    description,
  ];
}

/// `POST /transfers/quote`: fee, FX rate and totals computed by the server.
class TransferQuote extends Equatable {
  const TransferQuote({
    required this.debitAmount,
    required this.debitCurrency,
    required this.creditAmount,
    required this.creditCurrency,
    required this.fee,
    required this.feeCurrency,
    required this.totalDebit,
    required this.destinationName,
    this.exchangeRate,
    this.dailyLimitRemaining,
  });

  final String debitAmount;
  final String debitCurrency;
  final String creditAmount;
  final String creditCurrency;
  final String fee;
  final String feeCurrency;
  final String? exchangeRate;
  final String totalDebit;
  final String destinationName;
  final String? dailyLimitRemaining;

  bool get isCrossCurrency => debitCurrency != creditCurrency;

  @override
  List<Object?> get props => [
    debitAmount,
    debitCurrency,
    creditAmount,
    creditCurrency,
    fee,
    feeCurrency,
    exchangeRate,
    totalDebit,
    destinationName,
    dailyLimitRemaining,
  ];
}

/// `POST /transfers` result.
class TransferReceipt extends Equatable {
  const TransferReceipt({
    required this.transactionId,
    required this.reference,
    required this.status,
    required this.debitAmount,
    required this.debitCurrency,
    required this.creditAmount,
    required this.creditCurrency,
    required this.fee,
    required this.sourceAccountNumber,
    required this.destinationAccountNumber,
    required this.destinationName,
    this.exchangeRate,
    this.description,
    this.createdAt,
  });

  final String transactionId;
  final String reference;
  final String status;
  final String debitAmount;
  final String debitCurrency;
  final String creditAmount;
  final String creditCurrency;
  final String fee;
  final String? exchangeRate;
  final String sourceAccountNumber;
  final String destinationAccountNumber;
  final String destinationName;
  final String? description;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    transactionId,
    reference,
    status,
    debitAmount,
    debitCurrency,
    creditAmount,
    creditCurrency,
    fee,
    exchangeRate,
    sourceAccountNumber,
    destinationAccountNumber,
    destinationName,
    description,
    createdAt,
  ];
}
