import 'package:flutter/material.dart';

import '../../../../core/language/language.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/money.dart';
import '../../model/bank_transaction.dart';
import '../../model/transaction_filter.dart';
import 'transaction_presenter.dart';
import '../../../../core/widgets/widgets.dart';

/// Bottom sheet editing type / status / currency / date range.
class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({super.key, required this.initial});

  final TransactionFilter initial;

  static Future<TransactionFilter?> show(
    BuildContext context,
    TransactionFilter initial,
  ) {
    return showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionFilterSheet(initial: initial),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _filter = widget.initial;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _filter.from != null && _filter.to != null
          ? DateTimeRange(start: _filter.from!, end: _filter.to!)
          : null,
    );
    if (range != null) {
      setState(
        () => _filter = _filter.copyWith(
          from: () => range.start,
          to: () => range.end,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.languageCode;

    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLabel(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );

    ChoiceChip chip(String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(
          label: AppLabel(label),
          selected: selected,
          onSelected: (_) => onTap(),
        );

    final dateLabel = _filter.from != null && _filter.to != null
        ? '${DateFormatter.date(_filter.from!, locale)} – ${DateFormatter.date(_filter.to!, locale)}'
        : 'selectDateRange'.tr;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLabel(
              'filters'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            section('filterType'.tr, [
              chip(
                'commonAll'.tr,
                _filter.type == null,
                () => setState(
                  () => _filter = _filter.copyWith(type: () => null),
                ),
              ),
              for (final t in TransactionType.all)
                chip(
                  TxPresenter.typeLabel(t),
                  _filter.type == t,
                  () =>
                      setState(() => _filter = _filter.copyWith(type: () => t)),
                ),
            ]),
            section('filterStatus'.tr, [
              chip(
                'commonAll'.tr,
                _filter.status == null,
                () => setState(
                  () => _filter = _filter.copyWith(status: () => null),
                ),
              ),
              for (final s in TransactionStatus.all)
                chip(
                  TxPresenter.statusLabel(s),
                  _filter.status == s,
                  () => setState(
                    () => _filter = _filter.copyWith(status: () => s),
                  ),
                ),
            ]),
            section('filterCurrency'.tr, [
              chip(
                'commonAll'.tr,
                _filter.currency == null,
                () => setState(
                  () => _filter = _filter.copyWith(currency: () => null),
                ),
              ),
              for (final c in Currencies.all)
                chip(
                  c,
                  _filter.currency == c,
                  () => setState(
                    () => _filter = _filter.copyWith(currency: () => c),
                  ),
                ),
            ]),
            section('filterDateRange'.tr, [
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: AppLabel(dateLabel),
                onPressed: _pickDates,
              ),
              if (_filter.from != null)
                ActionChip(
                  avatar: const Icon(Icons.close, size: 18),
                  label: AppLabel('commonReset'.tr),
                  onPressed: () => setState(
                    () => _filter = _filter.copyWith(
                      from: () => null,
                      to: () => null,
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'commonReset'.tr,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(TransactionFilter(query: widget.initial.query)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'commonApply'.tr,
                    onPressed: () => Navigator.of(context).pop(_filter),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
