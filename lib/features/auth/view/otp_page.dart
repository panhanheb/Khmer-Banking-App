import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../view_model/auth_bloc.dart';
import '../view_model/otp_bloc.dart';
import 'widgets/auth_scaffold.dart';

/// SMS code entry: verify the phone of a new account, or sign in by phone.
class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.args});

  final OtpArgs args;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text;
    if (!Validators.isSixDigits(code)) return;
    context.read<OtpBloc>().add(OtpSubmitted(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRegistration = widget.args.purpose == OtpPurpose.registration;
    return BlocConsumer<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          if (isRegistration) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.otpVerifiedRegistration)),
            );
          }
          // Either way the user is now signed in to Firebase.
          context.read<AuthBloc>().add(const AuthLoggedIn());
        } else if (state.status.isFailure) {
          _controller.clear();
        }
      },
      builder: (context, state) {
        final busy = state.status.isLoading;
        return AuthScaffold(
          title: isRegistration ? l10n.otpTitle : l10n.otpLoginTitle,
          subtitle: [
            l10n.otpSubtitle,
            if (widget.args.phone != null) widget.args.phone!,
          ].join('\n'),
          showBack: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OtpInput(
                controller: _controller,
                enabled: !busy,
                errorText: state.status.isFailure
                    ? localizedError(l10n, state.error!)
                    : null,
                onCompleted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: l10n.otpVerifyButton,
                isLoading: busy,
                onPressed: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}
