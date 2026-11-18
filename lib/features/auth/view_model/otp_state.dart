import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';

/// Why the OTP is being entered.
enum OtpPurpose { registration, loginMfa }

/// Route arguments for the OTP page.
class OtpArgs extends Equatable {
  const OtpArgs({
    required this.purpose,
    required this.challengeId,
    this.phone,
    this.devOtp,
  });

  final OtpPurpose purpose;
  final String challengeId;
  final String? phone;
  final String? devOtp;

  @override
  List<Object?> get props => [purpose, challengeId, phone, devOtp];
}

class OtpState extends Equatable {
  const OtpState({this.status = LoadStatus.initial, this.error});

  final LoadStatus status;
  final Object? error;

  @override
  List<Object?> get props => [status, error];
}
