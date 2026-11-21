import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/language/language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../accounts/view/widgets/account_presenter.dart';
import '../../auth/view_model/pin_setup_state.dart';
import '../../transactions/view/widgets/transaction_presenter.dart';
import '../view_model/home_bloc.dart';
import 'widgets/coming_soon_sheet.dart';
import 'widgets/quick_actions_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static String greeting(DateTime now) {
    if (now.hour < 12) return 'greetingMorning'.tr;
    if (now.hour < 17) return 'greetingAfternoon'.tr;
    return 'greetingEvening'.tr;
  }

  Future<void> _refresh(BuildContext context) {
    final completer = Completer<void>();
    context.read<HomeBloc>().add(HomeRefreshed(completer: completer));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (!state.hasData) {
              if (state.status.isFailure) {
                return AppErrorWidget(
                  message: localizedError(state.error!),
                  retryLabel: 'commonRetry'.tr,
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
                    title: 'totalBalance'.tr,
                    totals: state.totals,
                    hidden: state.balanceHidden,
                    toggleTooltip: state.balanceHidden
                        ? 'showBalance'.tr
                        : 'hideBalance'.tr,
                    onToggleVisibility: () => context.read<HomeBloc>().add(
                      const HomeBalanceVisibilityToggled(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(title: 'quickActions'.tr),
                  const QuickActionsGrid(),
                  const SizedBox(height: 12),
                  SectionHeader(
                    title: 'myAccounts'.tr,
                    actionLabel: 'commonSeeAll'.tr,
                    onAction: () => context.pushPage(Pages.accounts()),
                  ),
                  _AccountsCarousel(state: state),
                  const SizedBox(height: 12),
                  SectionHeader(
                    title: 'recentTransactions'.tr,
                    actionLabel: 'commonSeeAll'.tr,
                    onAction: () => context.showTab(MainTab.transactions),
                  ),
                  if (state.recentTransactions.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'noTransactionsYet'.tr,
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
                                onTap: () => context.pushPage(
                                  Pages.transactionDetail(tx.id, initial: tx),
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
    final theme = Theme.of(context);
    final user = state.user!;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.showTab(MainTab.profile),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gold.withValues(alpha: 0.25),
            child: AppLabel(
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
              AppLabel(
                HomePage.greeting(DateTime.now()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppLabel(
                user.displayName(context.languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => showComingSoonSheet(context, 'navHome'.tr),
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
    return Card(
      color: AppColors.gold.withValues(alpha: 0.16),
      child: ListTile(
        leading: const Icon(Icons.pin_outlined, color: AppColors.navy),
        title: AppLabel('pinNotSetBanner'.tr),
        trailing: FilledButton.tonal(
          onPressed: () => context.pushPage(Pages.setPin(PinSetupMode.set)),
          child: AppLabel('setPinAction'.tr),
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
                  onTap: () => context.pushPage(Pages.openAccount()),
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
                        AppLabel(
                          accounts.isEmpty
                              ? 'noAccountsYet'.tr
                              : 'openAccount'.tr,
                          textAlign: TextAlign.center,
                        ),
                        if (accounts.isEmpty) ...[
                          const SizedBox(height: 4),
                          AppLabel(
                            'openAccount'.tr,
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
            onTap: () => context.pushPage(
              Pages.accountDetail(account.id, initial: account),
            ),
          );
        },
      ),
    );
  }
}
