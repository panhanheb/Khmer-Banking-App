import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../view_model/change_password_bloc.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<ChangePasswordBloc>().add(
      ChangePasswordSubmitted(
        currentPassword: _current.text,
        newPassword: _new.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          HapticFeedback.mediumImpact();
          TextInput.finishAutofillContext();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
          context.popPage();
        } else if (state.status.isFailure) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizedError(l10n, state.error!))),
          );
        }
      },
      builder: (context, state) {
        final busy = state.status.isLoading;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.changePassword)),
          body: AutofillGroup(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppTextField(
                    controller: _current,
                    label: l10n.currentPasswordLabel,
                    prefixIcon: Icons.lock_outline,
                    obscure: true,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => (v == null || v.isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _new,
                    label: l10n.newPasswordLabel,
                    helperText: l10n.passwordPolicyHint,
                    prefixIcon: Icons.lock_reset,
                    obscure: true,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return l10n.validationRequired;
                      }
                      return Validators.isStrongPassword(v)
                          ? null
                          : l10n.validationPassword;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirm,
                    label: l10n.confirmPasswordLabel,
                    prefixIcon: Icons.lock_reset,
                    obscure: true,
                    enabled: !busy,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                    validator: (v) =>
                        v == _new.text ? null : l10n.validationPasswordMatch,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: l10n.commonSave,
                    isLoading: busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
