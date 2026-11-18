import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../view_model/auth_bloc.dart';
import '../view_model/otp_bloc.dart';
import '../widgets/auth_scaffold.dart';

/// OTP entry for phone verification (registration) or new-device MFA.
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
    final isMfa = widget.args.purpose == OtpPurpose.loginMfa;
    return BlocConsumer<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          if (isMfa) {
            context.read<AuthBloc>().add(const AuthLoggedIn());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.otpVerifiedRegistration)),
            );
            context.go(Routes.login);
          }
        } else if (state.status.isFailure) {
          _controller.clear();
        }
      },
      builder: (context, state) {
        final busy = state.status.isLoading;
        final devOtp = widget.args.devOtp;
        return AuthScaffold(
          title: isMfa ? l10n.otpMfaTitle : l10n.otpTitle,
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
              if (devOtp != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: AppBadge.simulated(l10n.otpDevHint(devOtp)),
                ),
              ],
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
