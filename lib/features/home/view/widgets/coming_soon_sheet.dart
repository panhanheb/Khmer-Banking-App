import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_button.dart';

/// Shown for features whose backend is not live yet (QR, bills, top-up…).
/// These require licensed external integrations (see docs/ARCHITECTURE.md §6).
Future<void> showComingSoonSheet(BuildContext context, String feature) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final l10n = context.l10n;
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch_outlined,
                size: 34,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoonTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.comingSoonMessage(feature),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: l10n.commonOk,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    },
  );
}
