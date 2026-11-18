import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/page_result.dart';
import '../model/bank_transaction.dart';
import '../model/transaction_filter.dart';
import 'transactions_event.dart';
import 'transactions_state.dart';

export 'transactions_event.dart';
export 'transactions_state.dart';

typedef TransactionPageLoader = Future<PageResult<BankTransaction>> Function({
  required int page,
  required int size,
  required TransactionFilter filter,
});

/// Paginated, filterable transaction list. Used for the global history
/// (`GET /transactions`) and for one account (`GET /accounts/{id}/transactions`).
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({required TransactionPageLoader loadPage, this.pageSize = 20})
      : _loadPage = loadPage,
        super(const TransactionsState()) {
    on<TransactionsStarted>((e, emit) => _reload(e.filter, emit));
    on<TransactionsFilterChanged>((e, emit) => _reload(e.filter, emit));
    on<TransactionsRefreshed>((e, emit) => _reload(state.filter, emit));
    on<TransactionsNextPageRequested>(_onNextPage);
  }

  final TransactionPageLoader _loadPage;
  final int pageSize;

  /// Bumped on every reload so stale responses are discarded.
  int _generation = 0;

  Future<void> _reload(
    TransactionFilter filter,
    Emitter<TransactionsState> emit,
  ) async {
    final generation = ++_generation;
    emit(TransactionsState(
      status: LoadStatus.loading,
      filter: filter,
      items: state.filter == filter ? state.items : const [],
    ));
    try {
      final result = await _loadPage(page: 0, size: pageSize, filter: filter);
      if (generation != _generation) return;
      emit(TransactionsState(
        status: LoadStatus.success,
        filter: filter,
        items: result.content,
        page: result.page,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      if (generation != _generation) return;
      emit(TransactionsState(
        status: LoadStatus.failure,
        filter: filter,
        error: e,
      ));
    }
  }

  Future<void> _onNextPage(
    TransactionsNextPageRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    if (state.status != LoadStatus.success ||
        state.loadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreError: () => null));
    try {
      final result = await _loadPage(
        page: state.page + 1,
        size: pageSize,
        filter: state.filter,
      );
      if (generation != _generation) return;
      final known = state.items.map((t) => t.id).toSet();
      emit(state.copyWith(
        items: [
          ...state.items,
          ...result.content.where((t) => !known.contains(t.id)),
        ],
        page: result.page,
        hasMore: result.hasMore,
        loadingMore: false,
      ));
    } catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(loadingMore: false, loadMoreError: () => e));
    }
  }
}
