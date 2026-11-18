import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_usecases.dart';
import 'login_event.dart';
import 'login_state.dart';

export 'login_event.dart';
export 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required LoginUseCase login})
      : _login = login,
        super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginReset>((_, emit) => emit(const LoginState()));
  }

  final LoginUseCase _login;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.status == LoginStatus.submitting) return;
    emit(const LoginState(status: LoginStatus.submitting));
    try {
      final result = await _login(phone: event.phone, password: event.password);
      if (result.mfaRequired) {
        emit(LoginState(
          status: LoginStatus.mfaRequired,
          challengeId: result.challengeId,
          devOtp: result.devOtp,
          phone: event.phone,
        ));
      } else {
        emit(const LoginState(status: LoginStatus.success));
      }
    } catch (e) {
      emit(LoginState(status: LoginStatus.failure, error: e));
    }
  }
}
