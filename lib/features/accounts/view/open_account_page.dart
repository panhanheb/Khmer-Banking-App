import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../model/account.dart';
import '../view_model/open_account_bloc.dart';
import 'widgets/account_presenter.dart';

/// Opens a new current or savings account (`POST /accounts`).
class OpenAccountPage extends StatefulWidget {
  const OpenAccountPage({super.key});

  @override
  State<OpenAccountPage> createState() => _OpenAccountPageState();
}

class _OpenAccountPageState extends State<OpenAccountPage> {
  final _nickname = TextEditingController();
  String _type = AccountType.current;
  String _currency = Currencies.usd;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final nickname = _nickname.text.trim();
    context.read<OpenAccountBloc>().add(OpenAccountSubmitted(
          OpenAccountParams(
            type: _type,
            currency: _currency,
            nickname: nickname.isEmpty ? null : nickname,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocConsumer<OpenAccountBloc, OpenAccountState>(
      listener: (context, state) {
        if (state.status.isSuccess && state.account != null) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.accountOpened)),
          );
          context.pushReplacement(
            Routes.accountDetail(state.account!.id),
            extra: state.account,
          );
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
          appBar: AppBar(title: Text(l10n.openAccountTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.accountType, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final type in AccountType.all)
                    ButtonSegment(
                      value: type,
                      icon: Icon(type == AccountType.savings
                          ? Icons.savings_outlined
                          : Icons.account_balance_wallet_outlined),
                      label: Text(AccountPresenter.typeLabel(l10n, type)),
                    ),
                ],
                selected: {_type},
                onSelectionChanged: busy
                    ? null
                    : (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              Text(l10n.currency, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              IgnorePointer(
                ignoring: busy,
                child: CurrencySelector(
                  selected: _currency,
                  onChanged: (c) => setState(() => _currency = c),
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _nickname,
                label: l10n.nicknameLabel,
                helperText: l10n.commonOptional,
                prefixIcon: Icons.label_outline,
                maxLength: 40,
                enabled: !busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: l10n.openAccount,
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
