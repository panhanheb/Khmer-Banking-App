import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
import '../view_model/transactions_bloc.dart';
import 'widgets/transaction_filter_sheet.dart';
import 'widgets/transactions_sliver.dart';

/// Full history with search, filters and infinite scroll.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final bloc = context.read<TransactionsBloc>();
      final q = value.trim();
      if ((bloc.state.filter.query ?? '') == q) return;
      bloc.add(TransactionsFilterChanged(
        bloc.state.filter.copyWith(query: () => q.isEmpty ? null : q),
      ));
    });
  }

  Future<void> _openFilters() async {
    final bloc = context.read<TransactionsBloc>();
    final result = await TransactionFilterSheet.show(context, bloc.state.filter);
    if (result != null && result != bloc.state.filter) {
      bloc.add(TransactionsFilterChanged(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      body: InfiniteScrollListener(
        child: RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<TransactionsBloc>()
              ..add(const TransactionsRefreshed());
            await bloc.stream.firstWhere((s) => !s.status.isLoading);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: l10n.searchTransactionsHint,
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<TransactionsBloc, TransactionsState>(
                        buildWhen: (a, b) => a.filter != b.filter,
                        builder: (context, state) {
                          final count = state.filter.activeFilterCount;
                          return Badge(
                            isLabelVisible: count > 0,
                            label: Text('$count'),
                            child: IconButton.filledTonal(
                              tooltip: l10n.filters,
                              onPressed: _openFilters,
                              icon: const Icon(Icons.tune),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const TransactionsSliver(),
            ],
          ),
        ),
      ),
    );
  }
}
