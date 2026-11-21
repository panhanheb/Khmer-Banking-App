import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../model/bank_transaction.dart';
import '../../model/transaction_filter.dart';
import 'transaction_presenter.dart';

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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.languageCode;

    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );

    ChoiceChip chip(String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        );

    final dateLabel = _filter.from != null && _filter.to != null
        ? '${DateFormatter.date(_filter.from!, locale)} – ${DateFormatter.date(_filter.to!, locale)}'
        : l10n.selectDateRange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.filters,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            section(l10n.filterType, [
              chip(
                l10n.commonAll,
                _filter.type == null,
                () => setState(
                  () => _filter = _filter.copyWith(type: () => null),
                ),
              ),
              for (final t in TransactionType.all)
                chip(
                  TxPresenter.typeLabel(l10n, t),
                  _filter.type == t,
                  () =>
                      setState(() => _filter = _filter.copyWith(type: () => t)),
                ),
            ]),
            section(l10n.filterStatus, [
              chip(
                l10n.commonAll,
                _filter.status == null,
                () => setState(
                  () => _filter = _filter.copyWith(status: () => null),
                ),
              ),
              for (final s in TransactionStatus.all)
                chip(
                  TxPresenter.statusLabel(l10n, s),
                  _filter.status == s,
                  () => setState(
                    () => _filter = _filter.copyWith(status: () => s),
                  ),
                ),
            ]),
            section(l10n.filterCurrency, [
              chip(
                l10n.commonAll,
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
            section(l10n.filterDateRange, [
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(dateLabel),
                onPressed: _pickDates,
              ),
              if (_filter.from != null)
                ActionChip(
                  avatar: const Icon(Icons.close, size: 18),
                  label: Text(l10n.commonReset),
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
                    label: l10n.commonReset,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(TransactionFilter(query: widget.initial.query)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: l10n.commonApply,
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
