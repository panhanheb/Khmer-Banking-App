import 'package:flutter/material.dart';

import '../../../../core/language/language.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/transaction_item.dart';
import '../../model/bank_transaction.dart';

/// Localized labels, colors and icons for transactions.
class TxPresenter {
  const TxPresenter._();

  static String typeLabel(String type) => switch (type) {
    TransactionType.transfer => 'txTypeTransfer'.tr,
    TransactionType.deposit => 'txTypeDeposit'.tr,
    TransactionType.withdrawal => 'txTypeWithdrawal'.tr,
    TransactionType.fee => 'txTypeFee'.tr,
    TransactionType.reversal => 'txTypeReversal'.tr,
    TransactionType.qrPayment => 'txTypeQrPayment'.tr,
    TransactionType.billPayment => 'txTypeBillPayment'.tr,
    TransactionType.topup => 'txTypeTopup'.tr,
    _ => type,
  };

  static String statusLabel(String status) => switch (status) {
    TransactionStatus.pending => 'txStatusPending'.tr,
    TransactionStatus.completed => 'txStatusCompleted'.tr,
    TransactionStatus.failed => 'txStatusFailed'.tr,
    TransactionStatus.reversed => 'txStatusReversed'.tr,
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

  static String title(BankTransaction tx) {
    final name = tx.counterpartyName;
    if (name != null && name.trim().isNotEmpty) return name;
    final desc = tx.description;
    if (desc != null && desc.trim().isNotEmpty) return desc;
    return typeLabel(tx.type);
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
    final tx = transaction;
    final created = tx.createdAt;
    final subtitle = [
      TxPresenter.typeLabel(tx.type),
      if (created != null) DateFormatter.time(created, context.languageCode),
    ].join(' · ');
    return TransactionItem(
      title: TxPresenter.title(tx),
      subtitle: subtitle,
      amount: tx.amount,
      currency: tx.currency,
      isDebit: tx.isDebit,
      icon: TxPresenter.icon(tx),
      hidden: hidden,
      statusLabel: tx.status == TransactionStatus.completed
          ? null
          : TxPresenter.statusLabel(tx.status),
      statusColor: TxPresenter.statusColor(tx.status),
      simulatedLabel: tx.simulated ? 'simulatedBadge'.tr : null,
      onTap: onTap,
    );
  }
}
