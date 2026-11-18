import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/app_event_bus.dart';
import '../../../core/bloc/load_status.dart';
import '../model/account_usecases.dart';
import 'accounts_event.dart';
import 'accounts_state.dart';

export 'accounts_event.dart';
export 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc({required GetAccountsUseCase getAccounts, AppEventBus? eventBus})
      : _getAccounts = getAccounts,
        super(const AccountsState()) {
    on<AccountsRequested>(_onRequested);
    _subscription = eventBus?.stream
        .where((e) => e == AppEvent.balancesChanged)
        .listen((_) => add(const AccountsRequested()));
  }

  final GetAccountsUseCase _getAccounts;
  StreamSubscription<AppEvent>? _subscription;

  Future<void> _onRequested(
    AccountsRequested event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsState(status: LoadStatus.loading, accounts: state.accounts));
    try {
      final accounts = await _getAccounts();
      emit(AccountsState(status: LoadStatus.success, accounts: accounts));
    } catch (e) {
      emit(AccountsState(
        status: LoadStatus.failure,
        accounts: state.accounts,
        error: e,
      ));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
