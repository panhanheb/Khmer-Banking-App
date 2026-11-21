import 'package:flutter/material.dart';

import '../../../../core/language/language.dart';
import '../../../../core/widgets/account_card.dart';
import '../../model/account.dart';

class AccountPresenter {
  const AccountPresenter._();

  static String typeLabel(String type) => type == AccountType.savings
      ? 'accountTypeSavings'.tr
      : 'accountTypeCurrent'.tr;

  static String statusLabel(String status) => switch (status) {
    AccountStatus.active => 'statusActive'.tr,
    AccountStatus.frozen => 'statusFrozen'.tr,
    AccountStatus.closed => 'statusClosed'.tr,
    _ => status,
  };

  static String title(Account a) {
    final nick = a.nickname;
    if (nick != null && nick.trim().isNotEmpty) return nick;
    return '${typeLabel(a.type)} ${a.currency}';
  }
}

/// [AccountCard] bound to an [Account].
class BankAccountCard extends StatelessWidget {
  const BankAccountCard({
    super.key,
    required this.account,
    this.hidden = false,
    this.onTap,
    this.width,
  });

  final Account account;
  final bool hidden;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AccountCard(
      width: width,
      title: AccountPresenter.title(account),
      typeLabel: AccountPresenter.typeLabel(account.type),
      accountNumber: account.accountNumber,
      currency: account.currency,
      balance: account.balance,
      hidden: hidden,
      savings: account.isSavings,
      statusLabel: account.isActive
          ? null
          : AccountPresenter.statusLabel(account.status),
      onTap: onTap,
    );
  }
}
