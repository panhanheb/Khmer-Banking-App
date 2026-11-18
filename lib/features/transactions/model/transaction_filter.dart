import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_formatter.dart';

/// Query for `GET /transactions` / `GET /accounts/{id}/transactions`.
class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.type,
    this.status,
    this.currency,
    this.from,
    this.to,
    this.query,
  });

  final String? type;
  final String? status;
  final String? currency;
  final DateTime? from;
  final DateTime? to;
  final String? query;

  bool get hasActiveFilters =>
      type != null || status != null || currency != null || from != null;

  int get activeFilterCount => [type, status, currency, from].where((e) => e != null).length;

  TransactionFilter copyWith({
    String? Function()? type,
    String? Function()? status,
    String? Function()? currency,
    DateTime? Function()? from,
    DateTime? Function()? to,
    String? Function()? query,
  }) =>
      TransactionFilter(
        type: type != null ? type() : this.type,
        status: status != null ? status() : this.status,
        currency: currency != null ? currency() : this.currency,
        from: from != null ? from() : this.from,
        to: to != null ? to() : this.to,
        query: query != null ? query() : this.query,
      );

  Map<String, dynamic> toQuery() => {
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (currency != null) 'currency': currency,
        if (from != null) 'from': DateFormatter.apiDate(from!),
        if (to != null) 'to': DateFormatter.apiDate(to!),
        if (query != null && query!.trim().isNotEmpty) 'q': query!.trim(),
      };

  @override
  List<Object?> get props => [type, status, currency, from, to, query];
}
