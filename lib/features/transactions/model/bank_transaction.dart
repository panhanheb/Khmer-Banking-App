import 'package:equatable/equatable.dart';

/// Transaction types (docs/API.md).
class TransactionType {
  const TransactionType._();
  static const transfer = 'TRANSFER';
  static const deposit = 'DEPOSIT';
  static const withdrawal = 'WITHDRAWAL';
  static const fee = 'FEE';
  static const reversal = 'REVERSAL';
  static const qrPayment = 'QR_PAYMENT';
  static const billPayment = 'BILL_PAYMENT';
  static const topup = 'TOPUP';
  static const all = [
    transfer,
    deposit,
    withdrawal,
    fee,
    reversal,
    qrPayment,
    billPayment,
    topup,
  ];
}

class TransactionStatus {
  const TransactionStatus._();
  static const pending = 'PENDING';
  static const completed = 'COMPLETED';
  static const failed = 'FAILED';
  static const reversed = 'REVERSED';
  static const all = [pending, completed, failed, reversed];
}

/// A ledger transaction from the perspective of one of the user's accounts.
/// Amounts are decimal strings.
class BankTransaction extends Equatable {
  const BankTransaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.status,
    required this.direction,
    required this.amount,
    required this.fee,
    required this.currency,
    required this.accountId,
    required this.simulated,
    this.description,
    this.counterpartyName,
    this.counterpartyAccount,
    this.createdAt,
  });

  final String id;
  final String reference;
  final String type;
  final String status;

  /// `DEBIT` or `CREDIT`.
  final String direction;
  final String amount;
  final String fee;
  final String currency;
  final String? description;
  final String? counterpartyName;
  final String? counterpartyAccount;
  final String accountId;

  /// Dev-only mock money (shown with a SIMULATED badge).
  final bool simulated;
  final DateTime? createdAt;

  bool get isDebit => direction == 'DEBIT';

  @override
  List<Object?> get props => [
    id,
    reference,
    type,
    status,
    direction,
    amount,
    fee,
    currency,
    description,
    counterpartyName,
    counterpartyAccount,
    accountId,
    simulated,
    createdAt,
  ];
}
