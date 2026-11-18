import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../accounts/presentation/widgets/account_presenter.dart';
import '../../../auth/presentation/view_model/pin_setup_state.dart';
import '../../../transactions/presentation/widgets/transaction_presenter.dart';
import '../view_model/home_bloc.dart';
import '../widgets/coming_soon_sheet.dart';
import '../widgets/quick_actions_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static String greeting(AppLocalizations l10n, DateTime now) {
    if (now.hour < 12) return l10n.greetingMorning;
    if (now.hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  Future<void> _refresh(BuildContext context) {
    final completer = Completer<void>();
    context.read<HomeBloc>().add(HomeRefreshed(completer: completer));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (!state.hasData) {
              if (state.status.isFailure) {
                return AppErrorWidget(
                  message: localizedError(l10n, state.error!),
                  retryLabel: l10n.commonRetry,
                  onRetry: () =>
                      context.read<HomeBloc>().add(const HomeStarted()),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: LoadingWidget.dashboard(),
              );
            }
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _Header(state: state),
                  const SizedBox(height: 16),
                  if (state.user?.pinSet == false) ...[
                    const _PinBanner(),
                    const SizedBox(height: 16),
                  ],
                  BalanceCard(
                    title: l10n.totalBalance,
                    totals: state.totals,
                    hidden: state.balanceHidden,
                    toggleTooltip:
                        state.balanceHidden ? l10n.showBalance : l10n.hideBalance,
                    onToggleVisibility: () => context
                        .read<HomeBloc>()
                        .add(const HomeBalanceVisibilityToggled()),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(title: l10n.quickActions),
                  const QuickActionsGrid(),
                  const SizedBox(height: 12),
                  SectionHeader(
                    title: l10n.myAccounts,
                    actionLabel: l10n.commonSeeAll,
                    onAction: () => context.push(Routes.accounts),
                  ),
                  _AccountsCarousel(state: state),
                  const SizedBox(height: 12),
                  SectionHeader(
                    title: l10n.recentTransactions,
                    actionLabel: l10n.commonSeeAll,
                    onAction: () => context.go(Routes.transactions),
                  ),
                  if (state.recentTransactions.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.noTransactionsYet,
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            for (final tx in state.recentTransactions)
                              BankTransactionTile(
                                transaction: tx,
                                hidden: state.balanceHidden,
                                onTap: () => context.push(
                                  Routes.transactionDetail(tx.id),
                                  extra: tx,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = state.user!;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(Routes.profile),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gold.withValues(alpha: 0.25),
            child: Text(
              user.initials,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HomePage.greeting(l10n, DateTime.now()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                user.displayName(context.languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => showComingSoonSheet(context, l10n.navHome),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _PinBanner extends StatelessWidget {
  const _PinBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      color: AppColors.gold.withValues(alpha: 0.16),
      child: ListTile(
        leading: const Icon(Icons.pin_outlined, color: AppColors.navy),
        title: Text(l10n.pinNotSetBanner),
        trailing: FilledButton.tonal(
          onPressed: () => context.push(Routes.setPin, extra: PinSetupMode.set),
          child: Text(l10n.setPinAction),
        ),
      ),
    );
  }
}

class _AccountsCarousel extends StatelessWidget {
  const _AccountsCarousel({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = state.accounts;
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == accounts.length) {
            return SizedBox(
              width: accounts.isEmpty ? 300 : 150,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(Routes.openAccount),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          accounts.isEmpty ? l10n.noAccountsYet : l10n.openAccount,
                          textAlign: TextAlign.center,
                        ),
                        if (accounts.isEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.openAccount,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final account = accounts[i];
          return BankAccountCard(
            width: 280,
            account: account,
            hidden: state.balanceHidden,
            onTap: () =>
                context.push(Routes.accountDetail(account.id), extra: account),
          );
        },
      ),
    );
  }
}
