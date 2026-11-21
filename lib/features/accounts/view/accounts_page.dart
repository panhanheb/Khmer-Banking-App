import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/language/language.dart';
import '../../../core/widgets/widgets.dart';
import '../view_model/accounts_bloc.dart';
import 'widgets/account_presenter.dart';

/// All of the user's accounts (`GET /accounts`).
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLabel('accountsTitle'.tr),
        actions: [
          IconButton(
            tooltip: 'openAccount'.tr,
            onPressed: () => context.pushPage(Pages.openAccount()),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(
        builder: (context, state) {
          if (state.accounts.isEmpty) {
            if (state.status.isFailure) {
              return AppErrorWidget(
                message: localizedError(state.error!),
                retryLabel: 'commonRetry'.tr,
                onRetry: () =>
                    context.read<AccountsBloc>().add(const AccountsRequested()),
              );
            }
            if (state.status.isLoading || state.status == LoadStatus.initial) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    LoadingWidget.card(height: 160),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
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
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<AccountsBloc>()
                ..add(const AccountsRequested());
              await bloc.stream.firstWhere((s) => !s.status.isLoading);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: state.accounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final account = state.accounts[i];
                return BankAccountCard(
                  account: account,
                  onTap: () => context.pushPage(
                    Pages.accountDetail(account.id, initial: account),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
