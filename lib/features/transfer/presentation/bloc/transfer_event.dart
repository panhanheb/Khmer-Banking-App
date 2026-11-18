import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account.dart';
import '../../domain/entities/transfer_entities.dart';

sealed class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

/// Step 0: load the user's accounts (optionally preselecting one).
final class TransferStarted extends TransferEvent {
  const TransferStarted({this.preselectedAccountId});

  final String? preselectedAccountId;

  @override
  List<Object?> get props => [preselectedAccountId];
}

/// Step 1: choose the source account.
final class TransferSourceSelected extends TransferEvent {
  const TransferSourceSelected(this.account);

  final Account account;

  @override
  List<Object?> get props => [account];
}

/// Step 2: resolve the recipient by account number or phone.
final class TransferRecipientLookupRequested extends TransferEvent {
  const TransferRecipientLookupRequested(this.query);

  final RecipientQuery query;

  @override
  List<Object?> get props => [query];
}

final class TransferRecipientCleared extends TransferEvent {
  const TransferRecipientCleared();
}

/// Steps 3–5: amount, currency, description.
final class TransferAmountChanged extends TransferEvent {
  const TransferAmountChanged(this.amount);

  final String amount;

  @override
  List<Object?> get props => [amount];
}

final class TransferCurrencyChanged extends TransferEvent {
  const TransferCurrencyChanged(this.currency);

  final String currency;

  @override
  List<Object?> get props => [currency];
}

final class TransferDescriptionChanged extends TransferEvent {
  const TransferDescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

/// Step 6: request a server quote and open the review screen. A fresh
/// Idempotency-Key is generated for every review.
final class TransferReviewRequested extends TransferEvent {
  const TransferReviewRequested();
}

/// Steps 7–8: confirm with the PIN and execute. Retries reuse the key.
final class TransferSubmitted extends TransferEvent {
  const TransferSubmitted(this.pin);

  final String pin;

  @override
  List<Object?> get props => [pin];
}

final class TransferStepBack extends TransferEvent {
  const TransferStepBack();
}

final class TransferErrorDismissed extends TransferEvent {
  const TransferErrorDismissed();
}

/// Starts a brand-new transfer (after the receipt was shown).
final class TransferReset extends TransferEvent {
  const TransferReset();
}
