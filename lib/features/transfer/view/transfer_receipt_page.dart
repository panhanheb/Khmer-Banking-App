import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/navigation.dart';
import '../../../core/language/language.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../transactions/model/bank_transaction.dart';
import '../../transactions/view/widgets/transaction_presenter.dart';
import '../model/transfer_entities.dart';

/// Result of `POST /transfers`.
class TransferReceiptPage extends StatelessWidget {
  const TransferReceiptPage({super.key, required this.receipt});

  final TransferReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.languageCode;
    final statusColor = TxPresenter.statusColor(receipt.status);
    final (title, icon) = switch (receipt.status) {
      TransactionStatus.completed => (
        'transferSuccessful'.tr,
        Icons.check_circle_rounded,
      ),
      TransactionStatus.failed => ('transferFailed'.tr, Icons.error_rounded),
      _ => ('transferPending'.tr, Icons.schedule_rounded),
    };
    final feeIsZero = DecimalAmount.tryParse(receipt.fee)?.isZero ?? false;
    final crossCurrency = receipt.debitCurrency != receipt.creditCurrency;
    final description = receipt.description;
    return Scaffold(
      appBar: AppBar(
        title: AppLabel('receiptTitle'.tr),
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
                  AppLabel(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  FittedBox(
                    child: AppLabel(
                      MoneyFormatter.format(
                        receipt.debitAmount,
                        receipt.debitCurrency,
                      ),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppLabel(
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
                    label: 'reference'.tr,
                    value: receipt.reference,
                    trailing: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'commonCopy'.tr,
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: receipt.reference),
                        );
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: AppLabel('commonCopied'.tr)),
                        );
                      },
                    ),
                  ),
                  DetailRow(
                    label: 'accountStatus'.tr,
                    value: '',
                    trailing: AppBadge(
                      label: TxPresenter.statusLabel(receipt.status),
                      color: statusColor,
                    ),
                  ),
                  DetailRow(
                    label: 'fromAccount'.tr,
                    value: receipt.sourceAccountNumber,
                  ),
                  DetailRow(
                    label: 'toAccount'.tr,
                    value:
                        '${receipt.destinationName}\n'
                        '${receipt.destinationAccountNumber}',
                  ),
                  if (crossCurrency) ...[
                    DetailRow(
                      label: 'recipientGets'.tr,
                      value: MoneyFormatter.format(
                        receipt.creditAmount,
                        receipt.creditCurrency,
                      ),
                    ),
                    if (receipt.exchangeRate != null)
                      DetailRow(
                        label: 'exchangeRate'.tr,
                        value:
                            '1 ${receipt.debitCurrency} = '
                            '${MoneyFormatter.formatRate(receipt.exchangeRate!)} '
                            '${receipt.creditCurrency}',
                      ),
                  ],
                  DetailRow(
                    label: 'fee'.tr,
                    value: feeIsZero
                        ? 'free'.tr
                        : MoneyFormatter.format(
                            receipt.fee,
                            receipt.debitCurrency,
                          ),
                  ),
                  if (description != null && description.isNotEmpty)
                    DetailRow(label: 'description'.tr, value: description),
                  if (receipt.createdAt != null)
                    DetailRow(
                      label: 'dateTime'.tr,
                      value: DateFormatter.dateTime(receipt.createdAt!, locale),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'commonDone'.tr,
            onPressed: () => context.showTab(MainTab.home),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'newTransfer'.tr,
            variant: AppButtonVariant.outline,
            onPressed: () => context.popPage(),
          ),
        ],
      ),
    );
  }
}
