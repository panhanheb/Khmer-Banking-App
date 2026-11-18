import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/money.dart';

/// Segmented USD / KHR picker.
class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.currencies = Currencies.all,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> currencies;

  static String symbolOf(String currency) =>
      currency == Currencies.khr ? '៛' : r'$';

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        for (final c in currencies)
          ButtonSegment<String>(
            value: c,
            label: Text('${symbolOf(c)}  $c'),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (values) {
        HapticFeedback.selectionClick();
        onChanged(values.first);
      },
    );
  }
}
