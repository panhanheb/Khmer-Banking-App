import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/utils/money.dart';
import '../../accounts/model/account.dart';
import '../../profile/model/user_profile.dart';
import '../../transactions/model/bank_transaction.dart';

class HomeState extends Equatable {
  const HomeState({
    this.status = LoadStatus.initial,
    this.user,
    this.accounts = const [],
    this.recentTransactions = const [],
    this.balanceHidden = false,
    this.error,
  });

  final LoadStatus status;
  final UserProfile? user;
  final List<Account> accounts;
  final List<BankTransaction> recentTransactions;
  final bool balanceHidden;
  final Object? error;

  bool get hasData => user != null;

  /// Exact per-currency totals of non-closed accounts (USD first).
  Map<String, String> get totals {
    final result = <String, String>{};
    for (final currency in Currencies.all) {
      final balances = accounts
          .where(
            (a) => a.currency == currency && a.status != AccountStatus.closed,
          )
          .map((a) => a.balance)
          .toList();
      if (balances.isEmpty) continue;
      result[currency] = MoneyFormatter.sum(balances).toApiString(currency);
    }
    return result;
  }

  HomeState copyWith({
    LoadStatus? status,
    UserProfile? user,
    List<Account>? accounts,
    List<BankTransaction>? recentTransactions,
    bool? balanceHidden,
    Object? Function()? error,
  }) => HomeState(
    status: status ?? this.status,
    user: user ?? this.user,
    accounts: accounts ?? this.accounts,
    recentTransactions: recentTransactions ?? this.recentTransactions,
    balanceHidden: balanceHidden ?? this.balanceHidden,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [
    status,
    user,
    accounts,
    recentTransactions,
    balanceHidden,
    error,
  ];
}
