import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';

/// Why the SMS code is being entered.
enum OtpPurpose {
  /// Verify the phone number of a new account (links it to the account).
  registration,

  /// Sign in with phone number.
  phoneLogin,
}

/// Route arguments for the OTP page.
class OtpArgs extends Equatable {
  const OtpArgs({
    required this.purpose,
    required this.verificationId,
    this.phone,
  });

  final OtpPurpose purpose;

  /// Firebase phone verification id.
  final String verificationId;
  final String? phone;

  @override
  List<Object?> get props => [purpose, verificationId, phone];
}

class OtpState extends Equatable {
  const OtpState({this.status = LoadStatus.initial, this.error});

  final LoadStatus status;
  final Object? error;

  @override
  List<Object?> get props => [status, error];
}
