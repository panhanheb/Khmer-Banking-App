import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/money.dart';
import 'app_label.dart';

/// Hero card showing total balances per currency with a hide/show toggle.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.title,
    required this.totals,
    required this.hidden,
    required this.onToggleVisibility,
    this.toggleTooltip,
  });

  final String title;

  /// Currency code → decimal string total (e.g. `{'USD': '1250.00'}`).
  final Map<String, String> totals;
  final bool hidden;
  final VoidCallback onToggleVisibility;
  final String? toggleTooltip;

  @override
  Widget build(BuildContext context) {
    final entries = totals.entries.toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 12, 22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppLabel(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: toggleTooltip,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onToggleVisibility();
                    },
                    icon: Icon(
                      hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (entries.isEmpty)
                _AmountText(
                  text: hidden
                      ? MoneyFormatter.hiddenMask
                      : MoneyFormatter.format('0', Currencies.usd),
                  large: true,
                ),
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                  child: _AmountText(
                    text: hidden
                        ? '${MoneyFormatter.hiddenMask} ${entries[i].key}'
                        : MoneyFormatter.format(
                            entries[i].value,
                            entries[i].key,
                          ),
                    large: i == 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({required this.text, required this.large});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: FittedBox(
        key: ValueKey(text),
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: AppLabel(
          text,
          style: TextStyle(
            color: large ? Colors.white : AppColors.gold,
            fontSize: large ? 32 : 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
