import 'user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.phone,
    required super.fullNameEn,
    super.email,
    super.fullNameKm,
    super.language,
    super.kycStatus,
    super.pinSet,
    super.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String,
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        fullNameEn: json['fullNameEn'] as String? ?? '',
        fullNameKm: json['fullNameKm'] as String?,
        language: json['language'] as String?,
        kycStatus: json['kycStatus'] as String? ?? 'PENDING',
        pinSet: json['pinSet'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'fullNameEn': fullNameEn,
        'fullNameKm': fullNameKm,
        'language': language,
        'kycStatus': kycStatus,
        'pinSet': pinSet,
        'createdAt': createdAt?.toUtc().toIso8601String(),
      };
}
