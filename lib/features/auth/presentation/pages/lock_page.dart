import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../bloc/auth_bloc.dart';

/// Local biometric quick-unlock. This only gates access to the app on this
/// device; it never replaces server-side credentials or the transaction PIN.
class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await sl<BiometricService>()
        .authenticate(context.l10n.biometricReasonUnlock);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
    });
    if (ok) {
      HapticFeedback.mediumImpact();
      context.read<AuthBloc>().add(const AuthUnlocked());
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const BrandLogo(size: 80),
              const SizedBox(height: 24),
              Text(
                l10n.lockTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),
              IconButton.filledTonal(
                iconSize: 48,
                onPressed: _busy ? null : _unlock,
                icon: const Icon(Icons.fingerprint),
              ),
              if (_failed) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.biometricFailed,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const Spacer(),
              AppButton(
                label: l10n.lockUnlockButton,
                isLoading: _busy,
                onPressed: _unlock,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: l10n.lockUsePassword,
                variant: AppButtonVariant.text,
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
