import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../transactions/domain/entities/bank_transaction.dart';
import '../../../transactions/presentation/widgets/transaction_presenter.dart';
import '../../domain/entities/transfer_entities.dart';

/// Result of `POST /transfers`.
class TransferReceiptPage extends StatelessWidget {
  const TransferReceiptPage({super.key, required this.receipt});

  final TransferReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.languageCode;
    final statusColor = TxPresenter.statusColor(receipt.status);
    final (title, icon) = switch (receipt.status) {
      TransactionStatus.completed => (
          l10n.transferSuccessful,
          Icons.check_circle_rounded,
        ),
      TransactionStatus.failed => (l10n.transferFailed, Icons.error_rounded),
      _ => (l10n.transferPending, Icons.schedule_rounded),
    };
    final feeIsZero = DecimalAmount.tryParse(receipt.fee)?.isZero ?? false;
    final crossCurrency = receipt.debitCurrency != receipt.creditCurrency;
    final description = receipt.description;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receiptTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(icon, size: 64, color: statusColor),
                  const SizedBox(height: 12),
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  FittedBox(
                    child: Text(
                      MoneyFormatter.format(
                        receipt.debitAmount,
                        receipt.debitCurrency,
                      ),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receipt.destinationName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  DetailRow(
                    label: l10n.reference,
                    value: receipt.reference,
                    trailing: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.commonCopy,
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: receipt.reference),
                        );
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.commonCopied)),
                        );
                      },
                    ),
                  ),
                  DetailRow(
                    label: l10n.accountStatus,
                    value: '',
                    trailing: AppBadge(
                      label: TxPresenter.statusLabel(l10n, receipt.status),
                      color: statusColor,
                    ),
                  ),
                  DetailRow(
                    label: l10n.fromAccount,
                    value: receipt.sourceAccountNumber,
                  ),
                  DetailRow(
                    label: l10n.toAccount,
                    value: '${receipt.destinationName}\n'
                        '${receipt.destinationAccountNumber}',
                  ),
                  if (crossCurrency) ...[
                    DetailRow(
                      label: l10n.recipientGets,
                      value: MoneyFormatter.format(
                        receipt.creditAmount,
                        receipt.creditCurrency,
                      ),
                    ),
                    if (receipt.exchangeRate != null)
                      DetailRow(
                        label: l10n.exchangeRate,
                        value: '1 ${receipt.debitCurrency} = '
                            '${MoneyFormatter.formatRate(receipt.exchangeRate!)} '
                            '${receipt.creditCurrency}',
                      ),
                  ],
                  DetailRow(
                    label: l10n.fee,
                    value: feeIsZero
                        ? l10n.free
                        : MoneyFormatter.format(
                            receipt.fee,
                            receipt.debitCurrency,
                          ),
                  ),
                  if (description != null && description.isNotEmpty)
                    DetailRow(label: l10n.description, value: description),
                  if (receipt.createdAt != null)
                    DetailRow(
                      label: l10n.dateTime,
                      value: DateFormatter.dateTime(receipt.createdAt!, locale),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.commonDone,
            onPressed: () => context.go(Routes.home),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: l10n.newTransfer,
            variant: AppButtonVariant.outline,
            onPressed: () => context.go(Routes.transfer),
          ),
        ],
      ),
    );
  }
}
