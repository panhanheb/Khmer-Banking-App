import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/navigation.dart';
import '../../../../app/pages.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/language/language.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../model/bank_transaction.dart';
import '../../view_model/transactions_bloc.dart';
import 'transaction_presenter.dart';

/// Sliver rendering a [TransactionsBloc] list grouped by day, with skeleton,
/// empty, error and "load more" states. Place inside a [CustomScrollView]
/// wrapped by [InfiniteScrollListener].
class TransactionsSliver extends StatelessWidget {
  const TransactionsSliver({super.key, this.emptyTitle});

  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          if (state.status.isLoading || state.status == LoadStatus.initial) {
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: LoadingWidget.list()),
            );
          }
          if (state.status.isFailure) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: AppErrorWidget(
                message: localizedError(state.error!),
                retryLabel: 'commonRetry'.tr,
                onRetry: () => context.read<TransactionsBloc>().add(
                  const TransactionsRefreshed(),
                ),
              ),
            );
          }
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title:
                  emptyTitle ??
                  (state.filter.hasActiveFilters ||
                          (state.filter.query ?? '').isNotEmpty
                      ? 'noTransactionsFound'.tr
                      : 'noTransactionsYet'.tr),
            ),
          );
        }

        final rows = _buildRows(context, state.items);
        final footer = state.loadingMore
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            : state.loadMoreError != null
            ? TextButton.icon(
                onPressed: () => context.read<TransactionsBloc>().add(
                  const TransactionsNextPageRequested(),
                ),
                icon: const Icon(Icons.refresh),
                label: AppLabel('commonLoadMoreFailed'.tr),
              )
            : const SizedBox(height: 24);
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: rows.length + 1,
            itemBuilder: (context, i) => i < rows.length ? rows[i] : footer,
          ),
        );
      },
    );
  }

  List<Widget> _buildRows(BuildContext context, List<BankTransaction> items) {
    final locale = context.languageCode;
    final theme = Theme.of(context);
    final rows = <Widget>[];
    String? lastDay;
    for (final tx in items) {
      final created = tx.createdAt;
      final day = created == null ? '' : DateFormatter.date(created, locale);
      if (day != lastDay) {
        lastDay = day;
        if (day.isNotEmpty) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: AppLabel(
                day,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
      }
      rows.add(
        BankTransactionTile(
          transaction: tx,
          onTap: () =>
              context.pushPage(Pages.transactionDetail(tx.id, initial: tx)),
        ),
      );
    }
    return rows;
  }
}

/// Requests the next page when the user scrolls near the end.
class InfiniteScrollListener extends StatelessWidget {
  const InfiniteScrollListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 400) {
          context.read<TransactionsBloc>().add(
            const TransactionsNextPageRequested(),
          );
        }
        return false;
      },
      child: child,
    );
  }
}
