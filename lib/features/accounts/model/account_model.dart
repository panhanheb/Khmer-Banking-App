import 'account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.accountNumber,
    required super.type,
    required super.currency,
    required super.status,
    required super.balance,
    required super.availableBalance,
    super.nickname,
    super.openedAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
    id: json['id'] as String,
    accountNumber: json['accountNumber'] as String? ?? '',
    type: json['type'] as String? ?? AccountType.current,
    currency: json['currency'] as String? ?? 'USD',
    status: json['status'] as String? ?? AccountStatus.active,
    nickname: json['nickname'] as String?,
    balance: '${json['balance'] ?? '0'}',
    availableBalance: '${json['availableBalance'] ?? json['balance'] ?? '0'}',
    openedAt: DateTime.tryParse(json['openedAt'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountNumber': accountNumber,
    'type': type,
    'currency': currency,
    'status': status,
    'nickname': nickname,
    'balance': balance,
    'availableBalance': availableBalance,
    'openedAt': openedAt?.toUtc().toIso8601String(),
  };
}

class OpenAccountRequestModel {
  const OpenAccountRequestModel(this.params);

  final OpenAccountParams params;

  Map<String, dynamic> toJson() => {
    'type': params.type,
    'currency': params.currency,
    if (params.nickname != null && params.nickname!.trim().isNotEmpty)
      'nickname': params.nickname!.trim(),
  };
}
