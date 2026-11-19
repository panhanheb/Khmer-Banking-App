import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/login_usecases.dart';
import 'login_event.dart';
import 'login_state.dart';

export 'login_event.dart';
export 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required LoginWithEmailUseCase loginWithEmail,
    required SendPhoneLoginCodeUseCase sendPhoneCode,
  }) : _loginWithEmail = loginWithEmail,
       _sendPhoneCode = sendPhoneCode,
       super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginPhoneCodeRequested>(_onPhoneCodeRequested);
    on<LoginReset>((_, emit) => emit(const LoginState()));
  }

  final LoginWithEmailUseCase _loginWithEmail;
  final SendPhoneLoginCodeUseCase _sendPhoneCode;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.status == LoginStatus.submitting) return;
    emit(const LoginState(status: LoginStatus.submitting));
    try {
      await _loginWithEmail(email: event.email, password: event.password);
      emit(const LoginState(status: LoginStatus.success));
    } catch (e) {
      emit(LoginState(status: LoginStatus.failure, error: e));
    }
  }

  Future<void> _onPhoneCodeRequested(
    LoginPhoneCodeRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (state.status == LoginStatus.submitting) return;
    emit(const LoginState(status: LoginStatus.submitting));
    try {
      final result = await _sendPhoneCode(phone: event.phone);
      if (result.needsCode) {
        emit(
          LoginState(
            status: LoginStatus.codeSent,
            verificationId: result.verificationId,
            phone: event.phone,
          ),
        );
      } else {
        emit(const LoginState(status: LoginStatus.success));
      }
    } catch (e) {
      emit(LoginState(status: LoginStatus.failure, error: e));
    }
  }
}
