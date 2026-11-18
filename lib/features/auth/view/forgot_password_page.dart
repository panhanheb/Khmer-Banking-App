import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../view_model/password_reset_bloc.dart';
import 'widgets/auth_scaffold.dart';

/// Forgot password (request code) → reset password (code + new password).
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _requestForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    for (final c in [_phone, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _requestCode() {
    FocusScope.of(context).unfocus();
    if (!(_requestForm.currentState?.validate() ?? false)) return;
    context.read<PasswordResetBloc>().add(
          PasswordResetCodeRequested(Validators.normalizePhone(_phone.text)),
        );
  }

  void _reset() {
    FocusScope.of(context).unfocus();
    final codeOk = Validators.isSixDigits(_code.text);
    setState(() => _codeError = codeOk ? null : context.l10n.validationOtp);
    if (!(_resetForm.currentState?.validate() ?? false) || !codeOk) return;
    context.read<PasswordResetBloc>().add(PasswordResetSubmitted(
          code: _code.text,
          newPassword: _password.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<PasswordResetBloc, PasswordResetState>(
      listener: (context, state) {
        if (state.step == PasswordResetStep.done) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.resetSuccess)),
          );
          context.go(Routes.login);
        } else if (state.status.isFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizedError(l10n, state.error!))),
          );
        }
      },
      builder: (context, state) {
        final busy = state.status.isLoading;
        if (state.step == PasswordResetStep.requestCode) {
          return AuthScaffold(
            title: l10n.forgotTitle,
            subtitle: l10n.forgotSubtitle,
            showBack: true,
            showLogo: false,
            child: Form(
              key: _requestForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _phone,
                    label: l10n.phoneLabel,
                    hint: l10n.phoneHint,
                    prefixIcon: Icons.phone_iphone,
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _requestCode(),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : (Validators.isValidPhone(v)
                            ? null
                            : l10n.validationPhone),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: l10n.sendCodeButton,
                    isLoading: busy,
                    onPressed: _requestCode,
                  ),
                ],
              ),
            ),
          );
        }
        return AuthScaffold(
          title: l10n.resetTitle,
          subtitle: l10n.resetSubtitle,
          showBack: true,
          showLogo: false,
          child: Form(
            key: _resetForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.otpCodeLabel,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                OtpInput(
                  controller: _code,
                  errorText: _codeError,
                  onCompleted: (_) => setState(() => _codeError = null),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _password,
                  label: l10n.newPasswordLabel,
                  helperText: l10n.passwordPolicyHint,
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.validationRequired
                      : (Validators.isStrongPassword(v)
                          ? null
                          : l10n.validationPassword),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirm,
                  label: l10n.confirmPasswordLabel,
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  onSubmitted: (_) => _reset(),
                  validator: (v) => v == _password.text
                      ? null
                      : l10n.validationPasswordMatch,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: l10n.resetButton,
                  isLoading: busy,
                  onPressed: _reset,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
