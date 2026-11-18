import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/transaction_item.dart';
import '../../model/bank_transaction.dart';

/// Localized labels, colors and icons for transactions.
class TxPresenter {
  const TxPresenter._();

  static String typeLabel(AppLocalizations l10n, String type) => switch (type) {
        TransactionType.transfer => l10n.txTypeTransfer,
        TransactionType.deposit => l10n.txTypeDeposit,
        TransactionType.withdrawal => l10n.txTypeWithdrawal,
        TransactionType.fee => l10n.txTypeFee,
        TransactionType.reversal => l10n.txTypeReversal,
        TransactionType.qrPayment => l10n.txTypeQrPayment,
        TransactionType.billPayment => l10n.txTypeBillPayment,
        TransactionType.topup => l10n.txTypeTopup,
        _ => type,
      };

  static String statusLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        TransactionStatus.pending => l10n.txStatusPending,
        TransactionStatus.completed => l10n.txStatusCompleted,
        TransactionStatus.failed => l10n.txStatusFailed,
        TransactionStatus.reversed => l10n.txStatusReversed,
        _ => status,
      };

  static Color statusColor(String status) => switch (status) {
        TransactionStatus.completed => AppColors.success,
        TransactionStatus.failed => AppColors.error,
        TransactionStatus.reversed => AppColors.textSecondary,
        _ => AppColors.warning,
      };

  static IconData icon(BankTransaction tx) => switch (tx.type) {
        TransactionType.deposit => Icons.south_west_rounded,
        TransactionType.withdrawal => Icons.local_atm_outlined,
        TransactionType.fee => Icons.receipt_outlined,
        TransactionType.reversal => Icons.undo_rounded,
        TransactionType.qrPayment => Icons.qr_code_2_rounded,
        TransactionType.billPayment => Icons.lightbulb_outline,
        TransactionType.topup => Icons.phone_android_rounded,
        _ => tx.isDebit ? Icons.north_east_rounded : Icons.south_west_rounded,
      };

  static String title(AppLocalizations l10n, BankTransaction tx) {
    final name = tx.counterpartyName;
    if (name != null && name.trim().isNotEmpty) return name;
    final desc = tx.description;
    if (desc != null && desc.trim().isNotEmpty) return desc;
    return typeLabel(l10n, tx.type);
  }
}

/// [TransactionItem] bound to a [BankTransaction].
class BankTransactionTile extends StatelessWidget {
  const BankTransactionTile({
    super.key,
    required this.transaction,
    this.hidden = false,
    this.onTap,
  });

  final BankTransaction transaction;
  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tx = transaction;
    final created = tx.createdAt;
    final subtitle = [
      TxPresenter.typeLabel(l10n, tx.type),
      if (created != null) DateFormatter.time(created, context.languageCode),
    ].join(' · ');
    return TransactionItem(
      title: TxPresenter.title(l10n, tx),
      subtitle: subtitle,
      amount: tx.amount,
      currency: tx.currency,
      isDebit: tx.isDebit,
      icon: TxPresenter.icon(tx),
      hidden: hidden,
      statusLabel: tx.status == TransactionStatus.completed
          ? null
          : TxPresenter.statusLabel(l10n, tx.status),
      statusColor: TxPresenter.statusColor(tx.status),
      simulatedLabel: tx.simulated ? l10n.simulatedBadge : null,
      onTap: onTap,
    );
  }
}
