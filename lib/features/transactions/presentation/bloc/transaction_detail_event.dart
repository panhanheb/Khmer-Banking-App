import 'package:equatable/equatable.dart';

sealed class TransactionDetailEvent extends Equatable {
  const TransactionDetailEvent();

  @override
  List<Object?> get props => [];
}

final class TransactionDetailRequested extends TransactionDetailEvent {
  const TransactionDetailRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
