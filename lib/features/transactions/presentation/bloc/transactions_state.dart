import 'package:equatable/equatable.dart';

import '../../../../core/bloc/load_status.dart';
import '../../domain/entities/bank_transaction.dart';
import '../../domain/entities/transaction_filter.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.filter = const TransactionFilter(),
    this.page = -1,
    this.hasMore = true,
    this.loadingMore = false,
    this.loadMoreError,
    this.error,
  });

  final LoadStatus status;
  final List<BankTransaction> items;
  final TransactionFilter filter;

  /// Last loaded page index (-1 before the first load).
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final Object? loadMoreError;
  final Object? error;

  TransactionsState copyWith({
    LoadStatus? status,
    List<BankTransaction>? items,
    TransactionFilter? filter,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Object? Function()? loadMoreError,
    Object? Function()? error,
  }) =>
      TransactionsState(
        status: status ?? this.status,
        items: items ?? this.items,
        filter: filter ?? this.filter,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreError:
            loadMoreError != null ? loadMoreError() : this.loadMoreError,
        error: error != null ? error() : this.error,
      );

  @override
  List<Object?> get props =>
      [status, items, filter, page, hasMore, loadingMore, loadMoreError, error];
}
