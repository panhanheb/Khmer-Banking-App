import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/money.dart';
import 'badges.dart';

/// One row in a transaction list.
class TransactionItem extends StatelessWidget {
  const TransactionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.isDebit,
    required this.icon,
    this.statusLabel,
    this.statusColor,
    this.simulatedLabel,
    this.hidden = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String currency;
  final bool isDebit;
  final IconData icon;

  /// Shown when the transaction is not completed.
  final String? statusLabel;
  final Color? statusColor;

  /// Non-null → shows the SIMULATED badge.
  final String? simulatedLabel;
  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = isDebit ? theme.colorScheme.onSurface : AppColors.success;
    final amountText = hidden
        ? MoneyFormatter.hiddenMask
        : MoneyFormatter.format(
            isDebit ? '-$amount' : amount,
            currency,
            signed: !isDebit,
          );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDebit ? theme.colorScheme.primary : AppColors.success)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDebit ? theme.colorScheme.primary : AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (statusLabel != null)
                        AppBadge(
                          label: statusLabel!,
                          color: statusColor ?? AppColors.warning,
                        ),
                      if (simulatedLabel != null)
                        AppBadge.simulated(simulatedLabel!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
