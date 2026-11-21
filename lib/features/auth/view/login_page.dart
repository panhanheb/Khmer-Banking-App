import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/language/language.dart';
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
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'validationRequired'.tr : null;

    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.success:
            HapticFeedback.mediumImpact();
            TextInput.finishAutofillContext();
            context.read<AuthBloc>().add(const AuthLoggedIn());
          case LoginStatus.codeSent:
            context.pushPage(
              Pages.otp(
                OtpArgs(
                  purpose: OtpPurpose.phoneLogin,
                  verificationId: state.verificationId ?? '',
                  phone: state.phone,
                ),
              ),
            );
            context.read<LoginBloc>().add(const LoginReset());
          case LoginStatus.failure:
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppLabel(localizedError(state.error!))),
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
          title: 'loginTitle'.tr,
          subtitle: 'loginSubtitle'.tr,
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
                        label: AppLabel('loginMethodEmail'.tr),
                      ),
                      ButtonSegment(
                        value: _LoginMethod.phone,
                        icon: const Icon(Icons.phone_iphone),
                        label: AppLabel('loginMethodPhone'.tr),
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
                      label: 'emailLabel'.tr,
                      prefixIcon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) =>
                          required(v) ??
                          (Validators.isValidEmail(v!)
                              ? null
                              : 'validationEmail'.tr),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: const ValueKey('password'),
                      controller: _password,
                      label: 'passwordLabel'.tr,
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'validationRequired'.tr
                          : null,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: busy
                            ? null
                            : () => context.pushPage(Pages.forgotPassword()),
                        child: AppLabel('forgotPasswordLink'.tr),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    AppTextField(
                      key: const ValueKey('phone'),
                      controller: _phone,
                      label: 'phoneLabel'.tr,
                      hint: 'phoneHint'.tr,
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
                              : 'validationPhone'.tr),
                    ),
                    const SizedBox(height: 24),
                  ],
                  AppButton(
                    label: isEmail ? 'loginButton'.tr : 'sendCodeButton'.tr,
                    isLoading: busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: AppLabel('noAccountPrompt'.tr)),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => context.pushPage(Pages.register()),
                        child: AppLabel('registerLink'.tr),
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
