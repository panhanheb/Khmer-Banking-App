import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../app/routes.dart';
import '../../../../core/bloc/app_event_bus.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/pin_setup_bloc.dart';

/// Set (first time) or change the 6-digit transaction PIN.
class SetPinPage extends StatefulWidget {
  const SetPinPage({super.key, required this.mode});

  final PinSetupMode mode;

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == PinSetupMode.change
            ? l10n.changePinTitle
            : l10n.setPinTitle),
      ),
      body: BlocConsumer<PinSetupBloc, PinSetupState>(
        listenWhen: (a, b) => a.attempt != b.attempt || a.status != b.status,
        listener: (context, state) {
          _pin.clear();
          if (state.status.isSuccess) {
            HapticFeedback.mediumImpact();
            sl<AppEventBus>().emit(AppEvent.profileChanged);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.pinSetSuccess)),
            );
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.go(Routes.home);
            }
          }
        },
        builder: (context, state) {
          final prompt = switch (state.step) {
            PinSetupStep.current => l10n.pinEnterCurrent,
            PinSetupStep.enterNew => l10n.pinEnterNew,
            PinSetupStep.confirm => l10n.pinConfirmNew,
          };
          final error = switch (state.localError) {
            PinLocalError.weak => l10n.pinWeak,
            PinLocalError.mismatch => l10n.pinMismatch,
            null => state.error == null ? null : localizedError(l10n, state.error!),
          };
          return SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Icon(Icons.pin_outlined, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    prompt,
                    key: ValueKey(prompt),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                if (state.status.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                PinInput(
                  controller: _pin,
                  enabled: !state.status.isLoading,
                  errorText: error,
                  onCompleted: (pin) =>
                      context.read<PinSetupBloc>().add(PinSetupPinEntered(pin)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
