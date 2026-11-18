import 'package:equatable/equatable.dart';

class AccountType {
  const AccountType._();
  static const current = 'CURRENT';
  static const savings = 'SAVINGS';
  static const all = [current, savings];
}

class AccountStatus {
  const AccountStatus._();
  static const active = 'ACTIVE';
  static const frozen = 'FROZEN';
  static const closed = 'CLOSED';
}

/// Bank account. Balances are server-authoritative decimal strings.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.accountNumber,
    required this.type,
    required this.currency,
    required this.status,
    required this.balance,
    required this.availableBalance,
    this.nickname,
    this.openedAt,
  });

  final String id;
  final String accountNumber;
  final String type;
  final String currency;
  final String status;
  final String? nickname;
  final String balance;
  final String availableBalance;
  final DateTime? openedAt;

  bool get isActive => status == AccountStatus.active;
  bool get isSavings => type == AccountType.savings;

  String get maskedNumber => accountNumber.length <= 4
      ? accountNumber
      : '****${accountNumber.substring(accountNumber.length - 4)}';

  @override
  List<Object?> get props => [
        id,
        accountNumber,
        type,
        currency,
        status,
        nickname,
        balance,
        availableBalance,
        openedAt,
      ];
}

class OpenAccountParams extends Equatable {
  const OpenAccountParams({
    required this.type,
    required this.currency,
    this.nickname,
  });

  final String type;
  final String currency;
  final String? nickname;

  @override
  List<Object?> get props => [type, currency, nickname];
}
