import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/app_event_bus.dart';
import '../../../../core/bloc/load_status.dart';
import '../../domain/usecases/account_usecases.dart';
import 'open_account_event.dart';
import 'open_account_state.dart';

export 'open_account_event.dart';
export 'open_account_state.dart';

class OpenAccountBloc extends Bloc<OpenAccountEvent, OpenAccountState> {
  OpenAccountBloc({required OpenAccountUseCase openAccount, AppEventBus? eventBus})
      : _openAccount = openAccount,
        _eventBus = eventBus,
        super(const OpenAccountState()) {
    on<OpenAccountSubmitted>(_onSubmitted);
  }

  final OpenAccountUseCase _openAccount;
  final AppEventBus? _eventBus;

  Future<void> _onSubmitted(
    OpenAccountSubmitted event,
    Emitter<OpenAccountState> emit,
  ) async {
    if (state.status.isLoading) return;
    emit(const OpenAccountState(status: LoadStatus.loading));
    try {
      final account = await _openAccount(event.params);
      emit(OpenAccountState(status: LoadStatus.success, account: account));
      _eventBus?.emit(AppEvent.balancesChanged);
    } catch (e) {
      emit(OpenAccountState(status: LoadStatus.failure, error: e));
    }
  }
}
