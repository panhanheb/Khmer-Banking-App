import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/app_event_bus.dart';
import '../../../core/bloc/load_status.dart';
import '../../accounts/model/account_usecases.dart';
import '../../profile/model/get_current_user.dart';
import '../../transactions/model/transaction_usecases.dart';
import 'home_event.dart';
import 'home_state.dart';

export 'home_event.dart';
export 'home_state.dart';

/// Dashboard: profile, account balances and the 5 latest transactions.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetCurrentUserUseCase getCurrentUser,
    required GetAccountsUseCase getAccounts,
    required GetTransactionsUseCase getTransactions,
    AppEventBus? eventBus,
  })  : _getCurrentUser = getCurrentUser,
        _getAccounts = getAccounts,
        _getTransactions = getTransactions,
        super(const HomeState()) {
    on<HomeStarted>(_onLoad);
    on<HomeRefreshed>(_onLoad);
    on<HomeBalanceVisibilityToggled>(
      (_, emit) => emit(state.copyWith(balanceHidden: !state.balanceHidden)),
    );
    _subscription = eventBus?.stream
        .where((e) =>
            e == AppEvent.balancesChanged || e == AppEvent.profileChanged)
        .listen((_) => add(const HomeRefreshed()));
  }

  final GetCurrentUserUseCase _getCurrentUser;
  final GetAccountsUseCase _getAccounts;
  final GetTransactionsUseCase _getTransactions;
  StreamSubscription<AppEvent>? _subscription;

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading, error: () => null));
    try {
      final (user, accounts, page) = await (
        _getCurrentUser(),
        _getAccounts(),
        _getTransactions(page: 0, size: 5),
      ).wait;
      emit(state.copyWith(
        status: LoadStatus.success,
        user: user,
        accounts: accounts,
        recentTransactions: page.content,
      ));
    } on ParallelWaitError<dynamic, dynamic> catch (e) {
      emit(state.copyWith(
        status: LoadStatus.failure,
        error: () => _firstError(e.errors),
      ));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: () => e));
    } finally {
      if (event is HomeRefreshed) event.completer?.complete();
    }
  }

  /// Unwraps the first underlying error from a record `.wait` failure.
  static Object _firstError(Object? errors) {
    if (errors is (AsyncError?, AsyncError?, AsyncError?)) {
      final first = errors.$1 ?? errors.$2 ?? errors.$3;
      if (first != null) return first.error;
    }
    return errors ?? StateError('Unknown error');
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
