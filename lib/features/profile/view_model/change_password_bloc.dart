import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../auth/model/credential_usecases.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

export 'change_password_event.dart';
export 'change_password_state.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc({required ChangePasswordUseCase changePassword})
    : _changePassword = changePassword,
      super(const ChangePasswordState()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
  }

  final ChangePasswordUseCase _changePassword;

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (state.status.isLoading) return;
    emit(const ChangePasswordState(status: LoadStatus.loading));
    try {
      await _changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(const ChangePasswordState(status: LoadStatus.success));
    } catch (e) {
      emit(ChangePasswordState(status: LoadStatus.failure, error: e));
    }
  }
}
