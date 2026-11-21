import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/account_card.dart';
import '../../model/account.dart';

class AccountPresenter {
  const AccountPresenter._();

  static String typeLabel(AppLocalizations l10n, String type) =>
      type == AccountType.savings
      ? l10n.accountTypeSavings
      : l10n.accountTypeCurrent;

  static String statusLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        AccountStatus.active => l10n.statusActive,
        AccountStatus.frozen => l10n.statusFrozen,
        AccountStatus.closed => l10n.statusClosed,
        _ => status,
      };

  static String title(AppLocalizations l10n, Account a) {
    final nick = a.nickname;
    if (nick != null && nick.trim().isNotEmpty) return nick;
    return '${typeLabel(l10n, a.type)} ${a.currency}';
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
    final l10n = context.l10n;
    return AccountCard(
      width: width,
      title: AccountPresenter.title(l10n, account),
      typeLabel: AccountPresenter.typeLabel(l10n, account.type),
      accountNumber: account.accountNumber,
      currency: account.currency,
      balance: account.balance,
      hidden: hidden,
      savings: account.isSavings,
      statusLabel: account.isActive
          ? null
          : AccountPresenter.statusLabel(l10n, account.status),
      onTap: onTap,
    );
  }
}
