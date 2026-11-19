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

enum _LoginMethod { email, phone }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  _LoginMethod _method = _LoginMethod.email;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<LoginBloc>();
    switch (_method) {
      case _LoginMethod.email:
        bloc.add(
          LoginSubmitted(email: _email.text.trim(), password: _password.text),
        );
      case _LoginMethod.phone:
        bloc.add(
          LoginPhoneCodeRequested(Validators.normalizePhone(_phone.text)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.validationRequired : null;

    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.success:
            HapticFeedback.mediumImpact();
            TextInput.finishAutofillContext();
            context.read<AuthBloc>().add(const AuthLoggedIn());
          case LoginStatus.codeSent:
            context.push(
              Routes.otp,
              extra: OtpArgs(
                purpose: OtpPurpose.phoneLogin,
                verificationId: state.verificationId ?? '',
                phone: state.phone,
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
        final isEmail = _method == _LoginMethod.email;
        return AuthScaffold(
          title: l10n.loginTitle,
          subtitle: l10n.loginSubtitle,
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_LoginMethod>(
                    segments: [
                      ButtonSegment(
                        value: _LoginMethod.email,
                        icon: const Icon(Icons.alternate_email),
                        label: Text(l10n.loginMethodEmail),
                      ),
                      ButtonSegment(
                        value: _LoginMethod.phone,
                        icon: const Icon(Icons.phone_iphone),
                        label: Text(l10n.loginMethodPhone),
                      ),
                    ],
                    selected: {_method},
                    onSelectionChanged: busy
                        ? null
                        : (s) => setState(() {
                            _method = s.first;
                            _formKey.currentState?.reset();
                          }),
                  ),
                  const SizedBox(height: 20),
                  if (isEmail) ...[
                    AppTextField(
                      key: const ValueKey('email'),
                      controller: _email,
                      label: l10n.emailLabel,
                      prefixIcon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) =>
                          required(v) ??
                          (Validators.isValidEmail(v!)
                              ? null
                              : l10n.validationEmail),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: const ValueKey('password'),
                      controller: _password,
                      label: l10n.passwordLabel,
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? l10n.validationRequired
                          : null,
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
                  ] else ...[
                    AppTextField(
                      key: const ValueKey('phone'),
                      controller: _phone,
                      label: l10n.phoneLabel,
                      hint: l10n.phoneHint,
                      prefixIcon: Icons.phone_iphone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                      ],
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          required(v) ??
                          (Validators.isValidPhone(v!)
                              ? null
                              : l10n.validationPhone),
                    ),
                    const SizedBox(height: 24),
                  ],
                  AppButton(
                    label: isEmail ? l10n.loginButton : l10n.sendCodeButton,
                    isLoading: busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(l10n.noAccountPrompt)),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => context.push(Routes.register),
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
