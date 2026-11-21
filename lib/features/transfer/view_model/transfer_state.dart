import 'package:equatable/equatable.dart';

import '../../../core/utils/money.dart';
import '../../accounts/model/account.dart';
import '../model/transfer_entities.dart';

enum TransferStep { source, recipient, amount, review }

enum TransferOperation { loadAccounts, lookup, quote, submit }

enum AmountError { invalid, exceedsBalance }

class TransferState extends Equatable {
  const TransferState({
    this.step = TransferStep.source,
    this.accounts = const [],
    this.accountsLoaded = false,
    this.source,
    this.recipient,
    this.amount = '',
    this.currency,
    this.description = '',
    this.quote,
    this.idempotencyKey,
    this.receipt,
    this.pending,
    this.error,
    this.errorOrigin,
    this.amountError,
  });

  final TransferStep step;
  final List<Account> accounts;
  final bool accountsLoaded;
  final Account? source;
  final Recipient? recipient;

  /// Raw user input; normalised with [MoneyInput] before sending.
  final String amount;

  /// Currency of [amount]; must equal the source or destination currency.
  final String? currency;
  final String description;
  final TransferQuote? quote;

  /// Generated once per review screen and reused on every submit retry.
  final String? idempotencyKey;
  final TransferReceipt? receipt;
  final TransferOperation? pending;
  final Object? error;
  final TransferOperation? errorOrigin;
  final AmountError? amountError;

  bool get isBusy => pending != null;
  bool get isSubmitting => pending == TransferOperation.submit;
  bool get isCompleted => receipt != null;

  List<Account> get activeAccounts =>
      accounts.where((a) => a.isActive).toList(growable: false);

  /// Allowed currencies for the amount.
  List<String> get currencyOptions {
    final options = <String>{
      if (source != null) source!.currency,
      if (recipient != null) recipient!.currency,
    };
    return options.toList(growable: false);
  }

  String get effectiveCurrency =>
      currency ?? source?.currency ?? Currencies.usd;

  String? get normalizedAmount =>
      MoneyInput.normalize(amount, effectiveCurrency);

  bool get canRequestReview =>
      source != null && recipient != null && normalizedAmount != null;

  TransferRequest? get request {
    final s = source;
    final r = recipient;
    final a = normalizedAmount;
    if (s == null || r == null || a == null) return null;
    return TransferRequest(
      sourceAccountId: s.id,
      destinationAccountNumber: r.accountNumber,
      amount: a,
      currency: effectiveCurrency,
      description: description.trim().isEmpty ? null : description.trim(),
    );
  }

  TransferState copyWith({
    TransferStep? step,
    List<Account>? accounts,
    bool? accountsLoaded,
    Account? Function()? source,
    Recipient? Function()? recipient,
    String? amount,
    String? Function()? currency,
    String? description,
    TransferQuote? Function()? quote,
    String? Function()? idempotencyKey,
    TransferReceipt? Function()? receipt,
    TransferOperation? Function()? pending,
    Object? Function()? error,
    TransferOperation? Function()? errorOrigin,
    AmountError? Function()? amountError,
  }) {
    return TransferState(
      step: step ?? this.step,
      accounts: accounts ?? this.accounts,
      accountsLoaded: accountsLoaded ?? this.accountsLoaded,
      source: source != null ? source() : this.source,
      recipient: recipient != null ? recipient() : this.recipient,
      amount: amount ?? this.amount,
      currency: currency != null ? currency() : this.currency,
      description: description ?? this.description,
      quote: quote != null ? quote() : this.quote,
      idempotencyKey: idempotencyKey != null
          ? idempotencyKey()
          : this.idempotencyKey,
      receipt: receipt != null ? receipt() : this.receipt,
      pending: pending != null ? pending() : this.pending,
      error: error != null ? error() : this.error,
      errorOrigin: errorOrigin != null ? errorOrigin() : this.errorOrigin,
      amountError: amountError != null ? amountError() : this.amountError,
    );
  }

  @override
  List<Object?> get props => [
    step,
    accounts,
    accountsLoaded,
    source,
    recipient,
    amount,
    currency,
    description,
    quote,
    idempotencyKey,
    receipt,
    pending,
    error,
    errorOrigin,
    amountError,
  ];
}
