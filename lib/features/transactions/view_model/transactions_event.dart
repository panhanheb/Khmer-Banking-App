import 'package:equatable/equatable.dart';

import '../model/transaction_filter.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

final class TransactionsStarted extends TransactionsEvent {
  const TransactionsStarted({this.filter = const TransactionFilter()});

  final TransactionFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Replaces the filter (type/status/currency/date range/search) and reloads.
final class TransactionsFilterChanged extends TransactionsEvent {
  const TransactionsFilterChanged(this.filter);

  final TransactionFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Infinite scroll trigger.
final class TransactionsNextPageRequested extends TransactionsEvent {
  const TransactionsNextPageRequested();
}

final class TransactionsRefreshed extends TransactionsEvent {
  const TransactionsRefreshed();
}
