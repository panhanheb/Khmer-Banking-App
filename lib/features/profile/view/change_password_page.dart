import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/language/language.dart';
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
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          HapticFeedback.mediumImpact();
          TextInput.finishAutofillContext();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: AppLabel('passwordChanged'.tr)));
          context.popPage();
        } else if (state.status.isFailure) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppLabel(localizedError(state.error!))),
          );
        }
      },
      builder: (context, state) {
        final busy = state.status.isLoading;
        return Scaffold(
          appBar: AppBar(title: AppLabel('changePassword'.tr)),
          body: AutofillGroup(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppTextField(
                    controller: _current,
                    label: 'currentPasswordLabel'.tr,
                    prefixIcon: Icons.lock_outline,
                    obscure: true,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'validationRequired'.tr
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _new,
                    label: 'newPasswordLabel'.tr,
                    helperText: 'passwordPolicyHint'.tr,
                    prefixIcon: Icons.lock_reset,
                    obscure: true,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'validationRequired'.tr;
                      }
                      return Validators.isStrongPassword(v)
                          ? null
                          : 'validationPassword'.tr;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirm,
                    label: 'confirmPasswordLabel'.tr,
                    prefixIcon: Icons.lock_reset,
                    obscure: true,
                    enabled: !busy,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                    validator: (v) =>
                        v == _new.text ? null : 'validationPasswordMatch'.tr,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'commonSave'.tr,
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
