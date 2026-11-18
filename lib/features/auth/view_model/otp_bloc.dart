import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../domain/usecases/login_usecases.dart';
import '../../domain/usecases/registration_usecases.dart';
import 'otp_event.dart';
import 'otp_state.dart';

export 'otp_event.dart';
export 'otp_state.dart';

/// Verifies a registration OTP or completes a new-device (MFA) login.
class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({
    required this.args,
    required VerifyOtpUseCase verifyOtp,
    required VerifyLoginMfaUseCase verifyLoginMfa,
  })  : _verifyOtp = verifyOtp,
        _verifyLoginMfa = verifyLoginMfa,
        super(const OtpState()) {
    on<OtpSubmitted>(_onSubmitted);
  }

  final OtpArgs args;
  final VerifyOtpUseCase _verifyOtp;
  final VerifyLoginMfaUseCase _verifyLoginMfa;

  Future<void> _onSubmitted(OtpSubmitted event, Emitter<OtpState> emit) async {
    if (state.status.isLoading) return;
    emit(const OtpState(status: LoadStatus.loading));
    try {
      switch (args.purpose) {
        case OtpPurpose.registration:
          await _verifyOtp(challengeId: args.challengeId, code: event.code);
        case OtpPurpose.loginMfa:
          await _verifyLoginMfa(challengeId: args.challengeId, code: event.code);
      }
      emit(const OtpState(status: LoadStatus.success));
    } catch (e) {
      emit(OtpState(status: LoadStatus.failure, error: e));
    }
  }
}
