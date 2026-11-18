import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 6-digit transaction PIN entry with its own numeric keypad.
///
/// The system keyboard is never used, so the PIN is not exposed to
/// third-party keyboards / predictive text. Digits are always obscured.
class PinInput extends StatefulWidget {
  const PinInput({
    super.key,
    required this.onCompleted,
    this.length = 6,
    this.controller,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.onBiometric,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  /// Optional external controller (e.g. to clear the PIN after an error).
  final TextEditingController? controller;
  final String? errorText;
  final bool enabled;

  /// When set, a fingerprint key is shown in the bottom-left keypad slot.
  final VoidCallback? onBiometric;

  @override
  State<PinInput> createState() => PinInputState();
}

class PinInputState extends State<PinInput>
    with SingleTickerProviderStateMixin {
  TextEditingController? _ownController;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  String get value => _controller.text;

  void clear() => _controller.clear();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant PinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)
          ?.removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
    }
    if (widget.errorText != null && widget.errorText != oldWidget.errorText) {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _ownController?.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _press(String digit) {
    if (!widget.enabled || value.length >= widget.length) return;
    HapticFeedback.lightImpact();
    final next = value + digit;
    _controller.text = next;
    widget.onChanged?.call(next);
    if (next.length == widget.length) {
      widget.onCompleted(next);
    }
  }

  void _backspace() {
    if (!widget.enabled || value.isEmpty) return;
    HapticFeedback.selectionClick();
    final next = value.substring(0, value.length - 1);
    _controller.text = next;
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final dx = math.sin(_shake.value * math.pi * 6) *
                10 *
                (1 - _shake.value);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++)
                AnimatedContainer(
                  key: Key('pin_dot_$i'),
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < value.length
                        ? (hasError ? scheme.error : scheme.primary)
                        : Colors.transparent,
                    border: Border.all(
                      color: hasError ? scheme.error : scheme.outline,
                      width: 1.6,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: Center(
            child: hasError
                ? Text(
                    widget.errorText!,
                    key: const Key('pin_error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                  )
                : null,
          ),
        ),
        _Keypad(
          enabled: widget.enabled,
          onDigit: _press,
          onBackspace: _backspace,
          onBiometric: widget.onBiometric,
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => _KeypadButton(
          key: Key('pin_key_$d'),
          onTap: enabled ? () => onDigit(d) : null,
          child: Text(
            d,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
        );

    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) digit(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            onBiometric == null
                ? const SizedBox(width: 88, height: 68)
                : _KeypadButton(
                    key: const Key('pin_key_biometric'),
                    onTap: enabled ? onBiometric : null,
                    child: const Icon(Icons.fingerprint, size: 30),
                  ),
            digit('0'),
            _KeypadButton(
              key: const Key('pin_key_backspace'),
              onTap: enabled ? onBackspace : null,
              child: const Icon(Icons.backspace_outlined, size: 24),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: SizedBox(
        width: 76,
        height: 60,
        child: Material(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
