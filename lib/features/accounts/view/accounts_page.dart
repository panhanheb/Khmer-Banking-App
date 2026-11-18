import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../view_model/accounts_bloc.dart';
import 'widgets/account_presenter.dart';

/// All of the user's accounts (`GET /accounts`).
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
        actions: [
          IconButton(
            tooltip: l10n.openAccount,
            onPressed: () => context.push(Routes.openAccount),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(
        builder: (context, state) {
          if (state.accounts.isEmpty) {
            if (state.status.isFailure) {
              return AppErrorWidget(
                message: localizedError(l10n, state.error!),
                retryLabel: l10n.commonRetry,
                onRetry: () => context
                    .read<AccountsBloc>()
                    .add(const AccountsRequested()),
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
              title: l10n.noAccountsYet,
              action: FilledButton.icon(
                onPressed: () => context.push(Routes.openAccount),
                icon: const Icon(Icons.add),
                label: Text(l10n.openAccount),
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
                  onTap: () => context.push(
                    Routes.accountDetail(account.id),
                    extra: account,
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
