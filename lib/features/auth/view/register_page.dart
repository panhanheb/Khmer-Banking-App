import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/language/language.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../model/auth_entities.dart';
import '../view_model/auth_bloc.dart';
import '../view_model/otp_state.dart';
import '../view_model/register_bloc.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameEn = TextEditingController();
  final _nameKm = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nameEn, _nameKm, _phone, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<RegisterBloc>().add(
      RegisterSubmitted(
        RegisterParams(
          phone: Validators.normalizePhone(_phone.text),
          email: _email.text.trim(),
          password: _password.text,
          fullNameEn: _nameEn.text.trim(),
          fullNameKm: _nameKm.text.trim(),
          language: context.languageCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'validationRequired'.tr : null;

    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        final result = state.result;
        if (state.status.isSuccess && result != null) {
          HapticFeedback.mediumImpact();
          if (result.needsCode) {
            context.replacePage(
              Pages.otp(
                OtpArgs(
                  purpose: OtpPurpose.registration,
                  verificationId: result.verificationId!,
                  phone: state.phone,
                ),
              ),
            );
          } else {
            // Android verified the number automatically; account is ready.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppLabel('otpVerifiedRegistration'.tr)),
            );
            context.read<AuthBloc>().add(const AuthLoggedIn());
          }
        } else if (state.status.isFailure) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppLabel(localizedError(state.error!))),
          );
        }
      },
      builder: (context, state) {
        final busy = state.status.isLoading;
        return AuthScaffold(
          title: 'registerTitle'.tr,
          subtitle: 'registerSubtitle'.tr,
          showLogo: false,
          showBack: true,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameEn,
                  label: 'fullNameEnLabel'.tr,
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: required,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _nameKm,
                  label: 'fullNameKmLabel'.tr,
                  prefixIcon: Icons.translate,
                  textInputAction: TextInputAction.next,
                  validator: required,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phone,
                  label: 'phoneLabel'.tr,
                  hint: 'phoneHint'.tr,
                  prefixIcon: Icons.phone_iphone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  validator: (v) =>
                      required(v) ??
                      (Validators.isValidPhone(v!)
                          ? null
                          : 'validationPhone'.tr),
                ),
                const SizedBox(height: 14),
                AppTextField(
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
                const SizedBox(height: 14),
                AppTextField(
                  controller: _password,
                  label: 'passwordLabel'.tr,
                  helperText: 'passwordPolicyHint'.tr,
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) =>
                      required(v) ??
                      (Validators.isStrongPassword(v!)
                          ? null
                          : 'validationPassword'.tr),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirm,
                  label: 'confirmPasswordLabel'.tr,
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      required(v) ??
                      (v == _password.text
                          ? null
                          : 'validationPasswordMatch'.tr),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'registerButton'.tr,
                  isLoading: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: AppLabel('haveAccountPrompt'.tr)),
                    TextButton(
                      onPressed: busy ? null : () => context.popPage(),
                      child: AppLabel('loginButton'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
