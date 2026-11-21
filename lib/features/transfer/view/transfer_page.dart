import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/language/language.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../accounts/model/account.dart';
import '../../accounts/view/widgets/account_presenter.dart';
import '../../auth/view_model/pin_setup_state.dart';
import '../../settings/view_model/settings_bloc.dart';
import '../model/transfer_entities.dart';
import '../view_model/transfer_bloc.dart';

/// Transfer wizard: source → recipient → amount → review → PIN → receipt.
/// All state lives in [TransferBloc]; this page only renders the steps.
class TransferPage extends StatelessWidget {
  const TransferPage({super.key, this.preselectedAccountId});

  final String? preselectedAccountId;

  void _onStateChanged(BuildContext context, TransferState state) {
    final bloc = context.read<TransferBloc>();
    final receipt = state.receipt;
    if (receipt != null) {
      HapticFeedback.mediumImpact();
      context.pushPage(Pages.transferReceipt(receipt));
      bloc.add(const TransferReset());
      return;
    }
    final error = state.error;
    // Account loading failures are rendered full screen instead.
    if (error == null || state.errorOrigin == TransferOperation.loadAccounts) {
      return;
    }
    HapticFeedback.heavyImpact();
    final pinNotSet =
        error is ApiException && error.code == ApiException.pinNotSet;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppLabel(localizedError(error)),
        action: pinNotSet
            ? SnackBarAction(
                label: 'setPinAction'.tr,
                onPressed: () =>
                    context.pushPage(Pages.setPin(PinSetupMode.set)),
              )
            : null,
      ),
    );
    bloc.add(const TransferErrorDismissed());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransferBloc, TransferState>(
      listenWhen: (a, b) =>
          (b.receipt != null && a.receipt != b.receipt) ||
          (b.error != null && a.error != b.error),
      listener: _onStateChanged,
      builder: (context, state) {
        final canGoBack = state.step != TransferStep.source;
        return PopScope(
          canPop: !canGoBack,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              context.read<TransferBloc>().add(const TransferStepBack());
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: AppLabel('transferTitle'.tr),
              leading: canGoBack
                  ? BackButton(
                      onPressed: () => context.read<TransferBloc>().add(
                        const TransferStepBack(),
                      ),
                    )
                  : null,
            ),
            body: _body(context, state),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, TransferState state) {
    if (!state.accountsLoaded) {
      if (state.error != null &&
          state.errorOrigin == TransferOperation.loadAccounts) {
        return AppErrorWidget(
          message: localizedError(state.error!),
          retryLabel: 'commonRetry'.tr,
          onRetry: () => context.read<TransferBloc>().add(
            TransferStarted(preselectedAccountId: preselectedAccountId),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(16),
        child: LoadingWidget.list(count: 3),
      );
    }
    if (state.activeAccounts.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.account_balance_wallet_outlined,
        title: 'noAccountsYet'.tr,
        action: FilledButton.icon(
          onPressed: () => context.pushPage(Pages.openAccount()),
          icon: const Icon(Icons.add),
          label: AppLabel('openAccount'.tr),
        ),
      );
    }
    return Column(
      children: [
        _StepIndicator(step: state.step),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (state.step) {
              TransferStep.source => _SourceStep(
                key: const ValueKey(TransferStep.source),
                state: state,
              ),
              TransferStep.recipient => _RecipientStep(
                key: const ValueKey(TransferStep.recipient),
                state: state,
              ),
              TransferStep.amount => _AmountStep(
                key: const ValueKey(TransferStep.amount),
                state: state,
              ),
              TransferStep.review => _ReviewStep(
                key: const ValueKey(TransferStep.review),
                state: state,
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final TransferStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = [
      'stepFrom'.tr,
      'stepTo'.tr,
      'stepAmount'.tr,
      'stepReview'.tr,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: i == labels.length - 1 ? 0 : 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= step.index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppLabel(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: i == step.index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: i == step.index
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: source account

class _SourceStep extends StatelessWidget {
  const _SourceStep({super.key, required this.state});

  final TransferState state;

  @override
  Widget build(BuildContext context) {
    final accounts = state.activeAccounts;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: accounts.length + 1,
      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : 12),
      itemBuilder: (context, i) {
        if (i == 0) return SectionHeader(title: 'selectSourceAccount'.tr);
        final account = accounts[i - 1];
        return BankAccountCard(
          account: account,
          onTap: () =>
              context.read<TransferBloc>().add(TransferSourceSelected(account)),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: recipient lookup

class _RecipientStep extends StatefulWidget {
  const _RecipientStep({super.key, required this.state});

  final TransferState state;

  @override
  State<_RecipientStep> createState() => _RecipientStepState();
}

class _RecipientStepState extends State<_RecipientStep> {
  final _formKey = GlobalKey<FormState>();
  final _query = TextEditingController();
  bool _byPhone = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _lookup() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final text = _query.text.trim();
    final query = _byPhone
        ? RecipientQuery.byPhone(
            Validators.normalizePhone(text),
            currency: widget.state.source?.currency,
          )
        : RecipientQuery.byAccountNumber(text.replaceAll(' ', ''));
    context.read<TransferBloc>().add(TransferRecipientLookupRequested(query));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final busy = state.pending == TransferOperation.lookup;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (state.source != null)
            _AccountSummaryTile(
              label: 'fromAccount'.tr,
              account: state.source!,
              onChange: () =>
                  context.read<TransferBloc>().add(const TransferStepBack()),
            ),
          SectionHeader(title: 'recipientTitle'.tr),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.numbers),
                label: AppLabel('byAccountNumber'.tr),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.phone_iphone),
                label: AppLabel('byPhone'.tr),
              ),
            ],
            selected: {_byPhone},
            onSelectionChanged: busy
                ? null
                : (s) => setState(() {
                    _byPhone = s.first;
                    _query.clear();
                  }),
          ),
          const SizedBox(height: 16),
          AppTextField(
            key: ValueKey(_byPhone),
            controller: _query,
            label: _byPhone ? 'phoneLabel'.tr : 'accountNumber'.tr,
            hint: _byPhone ? 'phoneHint'.tr : null,
            prefixIcon: _byPhone ? Icons.phone_iphone : Icons.numbers,
            keyboardType: _byPhone ? TextInputType.phone : TextInputType.number,
            textInputAction: TextInputAction.search,
            enabled: !busy,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(_byPhone ? r'[0-9+ ]' : r'[0-9 ]'),
              ),
            ],
            onSubmitted: (_) => _lookup(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'validationRequired'.tr;
              if (_byPhone) {
                return Validators.isValidPhone(v) ? null : 'validationPhone'.tr;
              }
              return Validators.isValidAccountNumber(v)
                  ? null
                  : 'validationAccountNumber'.tr;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'findRecipient'.tr,
            icon: Icons.search,
            isLoading: busy,
            onPressed: _lookup,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: amount, currency, description

class _AmountStep extends StatefulWidget {
  const _AmountStep({super.key, required this.state});

  final TransferState state;

  @override
  State<_AmountStep> createState() => _AmountStepState();
}

class _AmountStepState extends State<_AmountStep> {
  late final _amount = TextEditingController(text: widget.state.amount);
  late final _description = TextEditingController(
    text: widget.state.description,
  );

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _review() {
    FocusScope.of(context).unfocus();
    context.read<TransferBloc>().add(const TransferReviewRequested());
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = context.read<TransferBloc>();
    final source = state.source!;
    final recipient = state.recipient!;
    final currency = state.effectiveCurrency;
    final busy = state.pending == TransferOperation.quote;
    final amountError = switch (state.amountError) {
      AmountError.invalid => 'validationAmount'.tr,
      AmountError.exceedsBalance => 'validationAmountExceedsBalance'.tr,
      null => null,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _AccountSummaryTile(
          label: 'fromAccount'.tr,
          account: source,
          onChange: busy
              ? null
              : () {
                  bloc
                    ..add(const TransferStepBack())
                    ..add(const TransferStepBack());
                },
        ),
        const SizedBox(height: 8),
        _RecipientTile(
          recipient: recipient,
          onChange: busy
              ? null
              : () => bloc.add(const TransferRecipientCleared()),
        ),
        const SizedBox(height: 16),
        if (state.currencyOptions.length > 1) ...[
          AppLabel(
            'currency'.tr,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: busy,
            child: CurrencySelector(
              selected: currency,
              currencies: state.currencyOptions,
              onChanged: (c) => bloc.add(TransferCurrencyChanged(c)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        AppTextField(
          controller: _amount,
          label: 'amountLabel'.tr,
          prefixIcon: currency == Currencies.khr
              ? Icons.currency_exchange
              : Icons.attach_money,
          helperText: currency == source.currency
              ? '${'availableBalance'.tr}: '
                    '${MoneyFormatter.format(source.availableBalance, source.currency)}'
              : null,
          errorText: amountError,
          enabled: !busy,
          keyboardType: TextInputType.numberWithOptions(
            decimal: Currencies.decimalsOf(currency) > 0,
          ),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(
                Currencies.decimalsOf(currency) > 0 ? r'[0-9.,]' : r'[0-9,]',
              ),
            ),
          ],
          onChanged: (v) => bloc.add(TransferAmountChanged(v)),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _description,
          label: 'description'.tr,
          hint: 'descriptionHint'.tr,
          helperText: 'commonOptional'.tr,
          prefixIcon: Icons.notes,
          maxLength: 100,
          enabled: !busy,
          textInputAction: TextInputAction.done,
          onChanged: (v) => bloc.add(TransferDescriptionChanged(v)),
          onSubmitted: (_) => _review(),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'reviewButton'.tr,
          isLoading: busy,
          onPressed: state.canRequestReview ? _review : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: review the server quote, confirm with biometrics (optional) + PIN

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({super.key, required this.state});

  final TransferState state;

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<TransferBloc>();
    final messenger = ScaffoldMessenger.of(context);
    if (context.read<SettingsBloc>().state.settings.biometricEnabled) {
      final ok = await sl<BiometricService>().authenticate(
        'biometricReasonTransfer'.tr,
      );
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: AppLabel('biometricFailed'.tr)),
        );
        return;
      }
    }
    if (!context.mounted) return;
    final pin = await _PinSheet.show(context);
    if (pin != null) bloc.add(TransferSubmitted(pin));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quote = state.quote!;
    final source = state.source!;
    final recipient = state.recipient!;
    final description = state.request?.description;
    final feeIsZero = DecimalAmount.tryParse(quote.fee)?.isZero ?? false;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppLabel(
                  'youSend'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  child: AppLabel(
                    MoneyFormatter.format(
                      quote.debitAmount,
                      quote.debitCurrency,
                    ),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AppLabel(
                  quote.destinationName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                DetailRow(
                  label: 'fromAccount'.tr,
                  value:
                      '${AccountPresenter.title(source)}\n'
                      '${source.maskedNumber}',
                ),
                DetailRow(
                  label: 'toAccount'.tr,
                  value:
                      '${quote.destinationName}\n'
                      '${recipient.accountNumber}\n${recipient.bankName}',
                ),
                if (quote.isCrossCurrency) ...[
                  DetailRow(
                    label: 'recipientGets'.tr,
                    value: MoneyFormatter.format(
                      quote.creditAmount,
                      quote.creditCurrency,
                    ),
                  ),
                  if (quote.exchangeRate != null)
                    DetailRow(
                      label: 'exchangeRate'.tr,
                      value:
                          '1 ${quote.debitCurrency} = '
                          '${MoneyFormatter.formatRate(quote.exchangeRate!)} '
                          '${quote.creditCurrency}',
                    ),
                ],
                DetailRow(
                  label: 'fee'.tr,
                  value: feeIsZero
                      ? 'free'.tr
                      : MoneyFormatter.format(quote.fee, quote.feeCurrency),
                ),
                if (description != null)
                  DetailRow(label: 'description'.tr, value: description),
                DetailRow(
                  label: 'totalDebit'.tr,
                  value: MoneyFormatter.format(
                    quote.totalDebit,
                    quote.debitCurrency,
                  ),
                  emphasize: true,
                ),
                if (quote.dailyLimitRemaining != null)
                  DetailRow(
                    label: 'dailyLimitRemaining'.tr,
                    value: MoneyFormatter.format(
                      quote.dailyLimitRemaining!,
                      quote.debitCurrency,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: state.isSubmitting ? 'processing'.tr : 'confirmAndSend'.tr,
          icon: Icons.lock_outline,
          isLoading: state.isSubmitting,
          onPressed: () => _confirm(context),
        ),
      ],
    );
  }
}

/// Bottom sheet that collects the 6-digit transaction PIN.
class _PinSheet extends StatelessWidget {
  const _PinSheet();

  static Future<String?> show(BuildContext context) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _PinSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLabel('enterPinTitle'.tr, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          AppLabel(
            'enterPinSubtitle'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          PinInput(onCompleted: (pin) => Navigator.of(context).pop(pin)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared summary tiles

class _AccountSummaryTile extends StatelessWidget {
  const _AccountSummaryTile({
    required this.label,
    required this.account,
    this.onChange,
  });

  final String label;
  final Account account;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          account.isSavings
              ? Icons.savings_outlined
              : Icons.account_balance_wallet_outlined,
        ),
        title: AppLabel(label),
        subtitle: AppLabel(
          '${AccountPresenter.title(account)} · ${account.maskedNumber}\n'
          '${MoneyFormatter.format(account.availableBalance, account.currency)}',
        ),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: onChange,
          child: AppLabel('commonChange'.tr),
        ),
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({required this.recipient, this.onChange});

  final Recipient recipient;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: AppLabel(recipient.accountName),
        subtitle: AppLabel(
          '${recipient.accountNumber} · ${recipient.currency}\n'
          '${recipient.bankName}',
        ),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: onChange,
          child: AppLabel('commonChange'.tr),
        ),
      ),
    );
  }
}
