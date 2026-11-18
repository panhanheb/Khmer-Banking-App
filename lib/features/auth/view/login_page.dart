import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../view_model/auth_bloc.dart';
import '../view_model/login_bloc.dart';
import '../view_model/otp_state.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<LoginBloc>().add(LoginSubmitted(
          phone: Validators.normalizePhone(_phone.text),
          password: _password.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.success:
            HapticFeedback.mediumImpact();
            TextInput.finishAutofillContext();
            context.read<AuthBloc>().add(const AuthLoggedIn());
          case LoginStatus.mfaRequired:
            context.push(
              Routes.otp,
              extra: OtpArgs(
                purpose: OtpPurpose.loginMfa,
                challengeId: state.challengeId ?? '',
                phone: state.phone,
                devOtp: state.devOtp,
              ),
            );
            context.read<LoginBloc>().add(const LoginReset());
          case LoginStatus.failure:
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizedError(l10n, state.error!))),
            );
          case LoginStatus.initial:
          case LoginStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        final busy = state.status == LoginStatus.submitting;
        return AuthScaffold(
          title: l10n.loginTitle,
          subtitle: l10n.loginSubtitle,
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _phone,
                    label: l10n.phoneLabel,
                    hint: l10n.phoneHint,
                    prefixIcon: Icons.phone_iphone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.validationRequired;
                      }
                      return Validators.isValidPhone(v) ? null : l10n.validationPhone;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _password,
                    label: l10n.passwordLabel,
                    prefixIcon: Icons.lock_outline,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.validationRequired : null,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => context.push(Routes.forgotPassword),
                      child: Text(l10n.forgotPasswordLink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: l10n.loginButton,
                    isLoading: busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(l10n.noAccountPrompt)),
                      TextButton(
                        onPressed:
                            busy ? null : () => context.push(Routes.register),
                        child: Text(l10n.registerLink),
                      ),
                    ],
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
