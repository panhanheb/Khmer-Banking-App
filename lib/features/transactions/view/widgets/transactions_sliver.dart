import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/bloc/load_status.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/bank_transaction.dart';
import '../view_model/transactions_bloc.dart';
import 'transaction_presenter.dart';

/// Sliver rendering a [TransactionsBloc] list grouped by day, with skeleton,
/// empty, error and "load more" states. Place inside a [CustomScrollView]
/// wrapped by [InfiniteScrollListener].
class TransactionsSliver extends StatelessWidget {
  const TransactionsSliver({super.key, this.emptyTitle});

  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                message: localizedError(l10n, state.error!),
                retryLabel: l10n.commonRetry,
                onRetry: () => context
                    .read<TransactionsBloc>()
                    .add(const TransactionsRefreshed()),
              ),
            );
          }
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: emptyTitle ??
                  (state.filter.hasActiveFilters ||
                          (state.filter.query ?? '').isNotEmpty
                      ? l10n.noTransactionsFound
                      : l10n.noTransactionsYet),
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
                    onPressed: () => context
                        .read<TransactionsBloc>()
                        .add(const TransactionsNextPageRequested()),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonLoadMoreFailed),
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
          rows.add(Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(
              day,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ));
        }
      }
      rows.add(BankTransactionTile(
        transaction: tx,
        onTap: () => context.push(Routes.transactionDetail(tx.id), extra: tx),
      ));
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
          context
              .read<TransactionsBloc>()
              .add(const TransactionsNextPageRequested());
        }
        return false;
      },
      child: child,
    );
  }
}
