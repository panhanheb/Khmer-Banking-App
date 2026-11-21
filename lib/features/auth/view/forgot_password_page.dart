import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../view_model/password_reset_bloc.dart';
import 'widgets/auth_scaffold.dart';

/// Forgot password: Firebase emails a link to choose a new password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetBloc>().add(
      PasswordResetRequested(_email.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<PasswordResetBloc, PasswordResetState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.resetLinkSent(state.email ?? ''))),
          );
          context.popPage();
        } else if (state.status.isFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizedError(l10n, state.error!))),
          );
        }
      },
      builder: (context, state) {
        return AuthScaffold(
          title: l10n.forgotTitle,
          subtitle: l10n.forgotSubtitle,
          showBack: true,
          showLogo: false,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _email,
                  label: l10n.emailLabel,
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _send(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.validationRequired
                      : (Validators.isValidEmail(v)
                            ? null
                            : l10n.validationEmail),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: l10n.sendResetLinkButton,
                  isLoading: state.status.isLoading,
                  onPressed: _send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
