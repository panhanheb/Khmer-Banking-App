import 'package:equatable/equatable.dart';

/// Result of starting a phone (SMS) verification.
///
/// On some Android devices Firebase verifies the number automatically
/// (instant verification / SMS auto-retrieval); then no code has to be typed
/// and [verificationId] is `null`.
class PhoneCodeResult extends Equatable {
  const PhoneCodeResult.codeSent(String this.verificationId);

  const PhoneCodeResult.autoVerified() : verificationId = null;

  final String? verificationId;

  bool get needsCode => verificationId != null;

  @override
  List<Object?> get props => [verificationId];
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.phone,
    required this.email,
    required this.password,
    required this.fullNameEn,
    required this.fullNameKm,
    required this.language,
  });

  final String phone;
  final String email;
  final String password;
  final String fullNameEn;
  final String fullNameKm;
  final String language;

  @override
  List<Object?> get props => [
    phone,
    email,
    password,
    fullNameEn,
    fullNameKm,
    language,
  ];
}

/// A device the user is signed in on.
class DeviceSession extends Equatable {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.trusted,
    required this.current,
    this.lastSeenAt,
  });

  final String id;
  final String deviceName;
  final String platform;
  final bool trusted;
  final bool current;
  final DateTime? lastSeenAt;

  @override
  List<Object?> get props => [
    id,
    deviceName,
    platform,
    trusted,
    current,
    lastSeenAt,
  ];
}
