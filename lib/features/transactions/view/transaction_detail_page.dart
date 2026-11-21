import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/language/language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../model/bank_transaction.dart';
import '../view_model/transaction_detail_bloc.dart';
import 'widgets/transaction_presenter.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppLabel('transactionDetails'.tr)),
      body: BlocBuilder<TransactionDetailBloc, TransactionDetailState>(
        builder: (context, state) {
          final tx = state.transaction;
          if (tx == null) {
            if (state.status.isFailure) {
              return AppErrorWidget(
                message: localizedError(state.error!),
                retryLabel: 'commonRetry'.tr,
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: LoadingWidget.card(height: 320),
            );
          }
          return _Details(tx: tx);
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.tx});

  final BankTransaction tx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.languageCode;
    final statusColor = TxPresenter.statusColor(tx.status);
    final amount = MoneyFormatter.format(
      tx.isDebit ? '-${tx.amount}' : tx.amount,
      tx.currency,
      signed: !tx.isDebit,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child: Icon(TxPresenter.icon(tx), color: statusColor),
                ),
                const SizedBox(height: 12),
                AppLabel(
                  TxPresenter.title(tx),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  child: AppLabel(
                    amount,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tx.isDebit ? null : AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    AppBadge(
                      label: TxPresenter.statusLabel(tx.status),
                      color: statusColor,
                    ),
                    if (tx.simulated) AppBadge.simulated('simulatedBadge'.tr),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (tx.simulated) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.warning.withValues(alpha: 0.1),
            child: ListTile(
              leading: const Icon(
                Icons.science_outlined,
                color: AppColors.warning,
              ),
              title: AppLabel('simulatedNotice'.tr),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                DetailRow(
                  label: 'reference'.tr,
                  value: tx.reference,
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'commonCopy'.tr,
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tx.reference));
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: AppLabel('commonCopied'.tr)),
                      );
                    },
                  ),
                ),
                DetailRow(
                  label: 'filterType'.tr,
                  value: TxPresenter.typeLabel(tx.type),
                ),
                if (tx.counterpartyName != null)
                  DetailRow(
                    label: 'counterparty'.tr,
                    value: [
                      tx.counterpartyName!,
                      if (tx.counterpartyAccount != null)
                        tx.counterpartyAccount!,
                    ].join('\n'),
                  ),
                if (tx.description != null && tx.description!.isNotEmpty)
                  DetailRow(label: 'description'.tr, value: tx.description!),
                DetailRow(
                  label: 'fee'.tr,
                  value: DecimalAmount.tryParse(tx.fee)?.isZero ?? true
                      ? 'free'.tr
                      : MoneyFormatter.format(tx.fee, tx.currency),
                ),
                if (tx.createdAt != null)
                  DetailRow(
                    label: 'dateTime'.tr,
                    value: DateFormatter.dateTime(tx.createdAt!, locale),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
