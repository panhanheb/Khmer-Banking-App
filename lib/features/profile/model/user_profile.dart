import 'package:equatable/equatable.dart';

/// `GET /users/me`.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.fullNameEn,
    this.email,
    this.fullNameKm,
    this.language,
    this.kycStatus = 'PENDING',
    this.pinSet = false,
    this.createdAt,
  });

  final String id;
  final String phone;
  final String? email;
  final String fullNameEn;
  final String? fullNameKm;
  final String? language;
  final String kycStatus;
  final bool pinSet;
  final DateTime? createdAt;

  /// Khmer name when the UI is Khmer and one is available.
  String displayName(String languageCode) {
    final km = fullNameKm;
    if (languageCode == 'km' && km != null && km.trim().isNotEmpty) return km;
    return fullNameEn;
  }

  String get initials {
    final parts = fullNameEn.trim().split(RegExp(r'\s+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    email,
    fullNameEn,
    fullNameKm,
    language,
    kycStatus,
    pinSet,
    createdAt,
  ];
}
