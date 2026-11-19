import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../model/login_usecases.dart';
import '../model/registration_usecases.dart';
import 'otp_event.dart';
import 'otp_state.dart';

export 'otp_event.dart';
export 'otp_state.dart';

/// Verifies an SMS code: links the phone to a new account, or signs in.
class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({
    required this.args,
    required VerifyRegistrationCodeUseCase verifyRegistrationCode,
    required VerifyPhoneLoginCodeUseCase verifyPhoneLoginCode,
  }) : _verifyRegistrationCode = verifyRegistrationCode,
       _verifyPhoneLoginCode = verifyPhoneLoginCode,
       super(const OtpState()) {
    on<OtpSubmitted>(_onSubmitted);
  }

  final OtpArgs args;
  final VerifyRegistrationCodeUseCase _verifyRegistrationCode;
  final VerifyPhoneLoginCodeUseCase _verifyPhoneLoginCode;

  Future<void> _onSubmitted(OtpSubmitted event, Emitter<OtpState> emit) async {
    if (state.status.isLoading) return;
    emit(const OtpState(status: LoadStatus.loading));
    try {
      switch (args.purpose) {
        case OtpPurpose.registration:
          await _verifyRegistrationCode(
            verificationId: args.verificationId,
            code: event.code,
          );
        case OtpPurpose.phoneLogin:
          await _verifyPhoneLoginCode(
            verificationId: args.verificationId,
            code: event.code,
          );
      }
      emit(const OtpState(status: LoadStatus.success));
    } catch (e) {
      emit(OtpState(status: LoadStatus.failure, error: e));
    }
  }
}
