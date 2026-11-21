import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../model/account.dart';
import '../model/account_usecases.dart';
import 'account_detail_event.dart';
import 'account_detail_state.dart';

export 'account_detail_event.dart';
export 'account_detail_state.dart';

/// Loads one account (`GET /accounts/{id}`). Its paginated history is
/// handled by a [TransactionsBloc] bound to the account endpoint.
class AccountDetailBloc extends Bloc<AccountDetailEvent, AccountDetailState> {
  AccountDetailBloc({
    required this.accountId,
    required GetAccountUseCase getAccount,
    Account? initial,
  }) : _getAccount = getAccount,
       super(
         AccountDetailState(
           status: initial == null ? LoadStatus.initial : LoadStatus.success,
           account: initial,
         ),
       ) {
    on<AccountDetailRequested>(_onRequested);
  }

  final String accountId;
  final GetAccountUseCase _getAccount;

  Future<void> _onRequested(
    AccountDetailRequested event,
    Emitter<AccountDetailState> emit,
  ) async {
    emit(
      AccountDetailState(status: LoadStatus.loading, account: state.account),
    );
    try {
      final account = await _getAccount(accountId);
      emit(AccountDetailState(status: LoadStatus.success, account: account));
    } catch (e) {
      emit(
        AccountDetailState(
          status: state.account == null
              ? LoadStatus.failure
              : LoadStatus.success,
          account: state.account,
          error: e,
        ),
      );
    }
  }
}
