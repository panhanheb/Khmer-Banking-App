import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../model/credential_usecases.dart';
import 'password_reset_event.dart';
import 'password_reset_state.dart';

export 'password_reset_event.dart';
export 'password_reset_state.dart';

class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  PasswordResetBloc({
    required ForgotPasswordUseCase forgotPassword,
    required ResetPasswordUseCase resetPassword,
  })  : _forgot = forgotPassword,
        _reset = resetPassword,
        super(const PasswordResetState()) {
    on<PasswordResetCodeRequested>(_onCodeRequested);
    on<PasswordResetSubmitted>(_onSubmitted);
  }

  final ForgotPasswordUseCase _forgot;
  final ResetPasswordUseCase _reset;

  Future<void> _onCodeRequested(
    PasswordResetCodeRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading, error: () => null));
    try {
      final challengeId = await _forgot(phone: event.phone);
      emit(state.copyWith(
        step: PasswordResetStep.enterCode,
        status: LoadStatus.initial,
        phone: event.phone,
        challengeId: challengeId,
      ));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: () => e));
    }
  }

  Future<void> _onSubmitted(
    PasswordResetSubmitted event,
    Emitter<PasswordResetState> emit,
  ) async {
    final challengeId = state.challengeId;
    if (challengeId == null) return;
    emit(state.copyWith(status: LoadStatus.loading, error: () => null));
    try {
      await _reset(
        challengeId: challengeId,
        code: event.code,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(
        step: PasswordResetStep.done,
        status: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: () => e));
    }
  }
}
