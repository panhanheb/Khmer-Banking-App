import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

/// Primary call-to-action button with a loading state and haptic feedback.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.haptic = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;
    void handlePress() {
      if (haptic) HapticFeedback.lightImpact();
      onPressed?.call();
    }

    final foreground = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => Colors.white,
      AppButtonVariant.secondary => scheme.onSecondary,
      AppButtonVariant.outline || AppButtonVariant.text => scheme.primary,
    };

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foreground,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: enabled ? handlePress : null,
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: enabled ? handlePress : null,
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
          ),
          onPressed: enabled ? handlePress : null,
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: enabled ? handlePress : null,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: enabled ? handlePress : null,
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
