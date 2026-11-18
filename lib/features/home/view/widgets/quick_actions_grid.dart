import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/l10n.dart';
import 'coming_soon_sheet.dart';

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;
}

/// Transfer, Scan QR, Deposit, Withdraw, Pay bills, Top up, History.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      _QuickAction(Icons.swap_horiz_rounded, l10n.actionTransfer,
          (c) => c.go(Routes.transfer)),
      _QuickAction(Icons.qr_code_scanner_rounded, l10n.actionScanQr,
          (c) => showComingSoonSheet(c, l10n.actionScanQr)),
      _QuickAction(Icons.add_card_rounded, l10n.actionDeposit,
          (c) => showComingSoonSheet(c, l10n.actionDeposit)),
      _QuickAction(Icons.local_atm_rounded, l10n.actionWithdraw,
          (c) => showComingSoonSheet(c, l10n.actionWithdraw)),
      _QuickAction(Icons.receipt_rounded, l10n.actionPayBills,
          (c) => showComingSoonSheet(c, l10n.actionPayBills)),
      _QuickAction(Icons.phone_android_rounded, l10n.actionTopUp,
          (c) => showComingSoonSheet(c, l10n.actionTopUp)),
      _QuickAction(Icons.history_rounded, l10n.actionHistory,
          (c) => c.go(Routes.transactions)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 500 ? 7 : 4;
            final width = constraints.maxWidth / columns;
            return Wrap(
              children: [
                for (final a in actions)
                  SizedBox(
                    width: width,
                    child: _ActionButton(action: a),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.lightImpact();
        action.onTap(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.14),
                    scheme.primary.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Icon(action.icon, color: scheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
