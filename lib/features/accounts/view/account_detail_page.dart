import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/language/language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../transactions/view_model/transactions_bloc.dart';
import '../../transactions/view/widgets/transactions_sliver.dart';
import '../model/account.dart';
import '../view_model/account_detail_bloc.dart';
import 'widgets/account_presenter.dart';

/// One account with its details and paginated history. Expects an
/// [AccountDetailBloc] and an account-scoped [TransactionsBloc] above it.
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppLabel('accountDetails'.tr)),
      body: BlocBuilder<AccountDetailBloc, AccountDetailState>(
        builder: (context, state) {
          final account = state.account;
          if (account == null) {
            if (state.status.isFailure) {
              return AppErrorWidget(
                message: localizedError(state.error!),
                retryLabel: 'commonRetry'.tr,
                onRetry: () => context.read<AccountDetailBloc>().add(
                  const AccountDetailRequested(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: LoadingWidget.card(height: 320),
            );
          }
          return InfiniteScrollListener(
            child: RefreshIndicator(
              onRefresh: () async {
                final detail = context.read<AccountDetailBloc>()
                  ..add(const AccountDetailRequested());
                final history = context.read<TransactionsBloc>()
                  ..add(const TransactionsRefreshed());
                await Future.wait([
                  detail.stream.firstWhere((s) => !s.status.isLoading),
                  history.stream.firstWhere((s) => !s.status.isLoading),
                ]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _AccountSummary(account: account),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(title: 'accountHistory'.tr),
                    ),
                  ),
                  const TransactionsSliver(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final locale = context.languageCode;
    final statusColor = switch (account.status) {
      AccountStatus.active => AppColors.success,
      AccountStatus.frozen => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BankAccountCard(account: account),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                DetailRow(
                  label: 'accountNumber'.tr,
                  value: AccountCard.groupAccountNumber(account.accountNumber),
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'commonCopy'.tr,
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: account.accountNumber),
                      );
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: AppLabel('commonCopied'.tr)),
                      );
                    },
                  ),
                ),
                DetailRow(
                  label: 'availableBalance'.tr,
                  value: MoneyFormatter.format(
                    account.availableBalance,
                    account.currency,
                  ),
                  emphasize: true,
                ),
                DetailRow(
                  label: 'ledgerBalance'.tr,
                  value: MoneyFormatter.format(
                    account.balance,
                    account.currency,
                  ),
                ),
                DetailRow(
                  label: 'accountType'.tr,
                  value: AccountPresenter.typeLabel(account.type),
                ),
                DetailRow(
                  label: 'accountStatus'.tr,
                  value: '',
                  trailing: AppBadge(
                    label: AccountPresenter.statusLabel(account.status),
                    color: statusColor,
                  ),
                ),
                if (account.openedAt != null)
                  DetailRow(
                    label: 'dateTime'.tr,
                    value: 'openedOn'.trParams({
                      'date': DateFormatter.date(account.openedAt!, locale),
                    }),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'actionTransfer'.tr,
          icon: Icons.send_rounded,
          onPressed: account.isActive
              ? () =>
                    context.pushPage(Pages.transfer(fromAccountId: account.id))
              : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
