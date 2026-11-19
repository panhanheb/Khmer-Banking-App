import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../model/credential_usecases.dart';
import 'password_reset_event.dart';
import 'password_reset_state.dart';

export 'password_reset_event.dart';
export 'password_reset_state.dart';

/// Sends a Firebase password reset email.
class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  PasswordResetBloc({required SendPasswordResetEmailUseCase sendResetEmail})
    : _sendResetEmail = sendResetEmail,
      super(const PasswordResetState()) {
    on<PasswordResetRequested>(_onRequested);
  }

  final SendPasswordResetEmailUseCase _sendResetEmail;

  Future<void> _onRequested(
    PasswordResetRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    if (state.status.isLoading) return;
    emit(const PasswordResetState(status: LoadStatus.loading));
    try {
      await _sendResetEmail(email: event.email);
      emit(PasswordResetState(status: LoadStatus.success, email: event.email));
    } catch (e) {
      emit(PasswordResetState(status: LoadStatus.failure, error: e));
    }
  }
}
