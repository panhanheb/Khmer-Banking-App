import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../model/registration_usecases.dart';
import 'register_event.dart';
import 'register_state.dart';

export 'register_event.dart';
export 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required RegisterUseCase register})
    : _register = register,
      super(const RegisterState()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  final RegisterUseCase _register;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (state.status.isLoading) return;
    emit(const RegisterState(status: LoadStatus.loading));
    try {
      final result = await _register(event.params);
      emit(
        RegisterState(
          status: LoadStatus.success,
          result: result,
          phone: event.params.phone,
        ),
      );
    } catch (e) {
      emit(RegisterState(status: LoadStatus.failure, error: e));
    }
  }
}
