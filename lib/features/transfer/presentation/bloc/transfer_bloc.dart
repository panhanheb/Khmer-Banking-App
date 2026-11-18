import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/bloc/app_event_bus.dart';
import '../../../../core/utils/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/usecases/account_usecases.dart';
import '../../domain/usecases/transfer_usecases.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

export 'transfer_event.dart';
export 'transfer_state.dart';

/// Drives the transfer wizard (skill.md §2.D):
/// source → recipient → amount/currency/description → review (server quote)
/// → PIN confirm → execute (idempotent) → receipt.
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc({
    required GetAccountsUseCase getAccounts,
    required LookupRecipientUseCase lookupRecipient,
    required GetTransferQuoteUseCase getQuote,
    required SubmitTransferUseCase submitTransfer,
    AppEventBus? eventBus,
    String Function()? idempotencyKeyGenerator,
  })  : _getAccounts = getAccounts,
        _lookupRecipient = lookupRecipient,
        _getQuote = getQuote,
        _submitTransfer = submitTransfer,
        _eventBus = eventBus,
        _newKey = idempotencyKeyGenerator ?? (() => const Uuid().v4()),
        super(const TransferState()) {
    on<TransferStarted>(_onStarted);
    on<TransferSourceSelected>(_onSourceSelected);
    on<TransferRecipientLookupRequested>(_onLookup);
    on<TransferRecipientCleared>(_onRecipientCleared);
    on<TransferAmountChanged>(_onAmountChanged);
    on<TransferCurrencyChanged>(_onCurrencyChanged);
    on<TransferDescriptionChanged>(_onDescriptionChanged);
    on<TransferReviewRequested>(_onReviewRequested);
    on<TransferSubmitted>(_onSubmitted);
    on<TransferStepBack>(_onStepBack);
    on<TransferErrorDismissed>(_onErrorDismissed);
    on<TransferReset>(_onReset);
  }

  final GetAccountsUseCase _getAccounts;
  final LookupRecipientUseCase _lookupRecipient;
  final GetTransferQuoteUseCase _getQuote;
  final SubmitTransferUseCase _submitTransfer;
  final AppEventBus? _eventBus;
  final String Function() _newKey;

  Future<void> _onStarted(
    TransferStarted event,
    Emitter<TransferState> emit,
  ) async {
    emit(state.copyWith(
      pending: () => TransferOperation.loadAccounts,
      error: () => null,
      errorOrigin: () => null,
    ));
    try {
      final accounts = await _getAccounts();
      Account? preselected;
      final active = accounts.where((a) => a.isActive).toList();
      if (event.preselectedAccountId != null) {
        for (final a in active) {
          if (a.id == event.preselectedAccountId) preselected = a;
        }
      }
      emit(state.copyWith(
        accounts: accounts,
        accountsLoaded: true,
        pending: () => null,
        source: preselected == null ? null : () => preselected,
        currency: preselected == null ? null : () => preselected!.currency,
        step: preselected == null ? null : TransferStep.recipient,
      ));
    } catch (e) {
      emit(state.copyWith(
        pending: () => null,
        error: () => e,
        errorOrigin: () => TransferOperation.loadAccounts,
      ));
    }
  }

  void _onSourceSelected(
    TransferSourceSelected event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      source: () => event.account,
      currency: () => event.account.currency,
      step: state.recipient == null
          ? TransferStep.recipient
          : TransferStep.amount,
      quote: () => null,
      idempotencyKey: () => null,
      amountError: () => null,
      error: () => null,
      errorOrigin: () => null,
    ));
  }

  Future<void> _onLookup(
    TransferRecipientLookupRequested event,
    Emitter<TransferState> emit,
  ) async {
    if (state.pending != null) return;
    emit(state.copyWith(
      pending: () => TransferOperation.lookup,
      error: () => null,
      errorOrigin: () => null,
    ));
    try {
      final recipient = await _lookupRecipient(event.query);
      emit(state.copyWith(
        pending: () => null,
        recipient: () => recipient,
        currency: () => state.source?.currency ?? recipient.currency,
        step: TransferStep.amount,
        quote: () => null,
        idempotencyKey: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        pending: () => null,
        error: () => e,
        errorOrigin: () => TransferOperation.lookup,
      ));
    }
  }

  void _onRecipientCleared(
    TransferRecipientCleared event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      recipient: () => null,
      step: TransferStep.recipient,
      quote: () => null,
      idempotencyKey: () => null,
      currency: () => state.source?.currency,
    ));
  }

  void _onAmountChanged(
    TransferAmountChanged event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      amount: event.amount,
      amountError: () => null,
      quote: () => null,
      idempotencyKey: () => null,
    ));
  }

  void _onCurrencyChanged(
    TransferCurrencyChanged event,
    Emitter<TransferState> emit,
  ) {
    if (!state.currencyOptions.contains(event.currency)) return;
    emit(state.copyWith(
      currency: () => event.currency,
      amountError: () => null,
      quote: () => null,
      idempotencyKey: () => null,
    ));
  }

  void _onDescriptionChanged(
    TransferDescriptionChanged event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  Future<void> _onReviewRequested(
    TransferReviewRequested event,
    Emitter<TransferState> emit,
  ) async {
    if (state.pending != null) return;
    final source = state.source;
    final normalized = state.normalizedAmount;
    if (source == null || state.recipient == null) return;
    if (normalized == null) {
      emit(state.copyWith(amountError: () => AmountError.invalid));
      return;
    }
    // Client-side pre-check only; the server re-validates everything.
    if (state.effectiveCurrency == source.currency) {
      final available = DecimalAmount.tryParse(source.availableBalance);
      final requested = DecimalAmount.parse(normalized);
      if (available != null && requested > available) {
        emit(state.copyWith(amountError: () => AmountError.exceedsBalance));
        return;
      }
    }
    final request = state.request!;
    emit(state.copyWith(
      pending: () => TransferOperation.quote,
      amountError: () => null,
      error: () => null,
      errorOrigin: () => null,
    ));
    try {
      final quote = await _getQuote(request);
      emit(state.copyWith(
        pending: () => null,
        quote: () => quote,
        step: TransferStep.review,
        // One key per review screen: reused for every retry of this transfer.
        idempotencyKey: () => _newKey(),
      ));
    } catch (e) {
      emit(state.copyWith(
        pending: () => null,
        error: () => e,
        errorOrigin: () => TransferOperation.quote,
      ));
    }
  }

  Future<void> _onSubmitted(
    TransferSubmitted event,
    Emitter<TransferState> emit,
  ) async {
    final request = state.request;
    final key = state.idempotencyKey;
    if (state.pending != null ||
        state.step != TransferStep.review ||
        state.quote == null ||
        state.receipt != null ||
        key == null ||
        request == null) {
      return;
    }
    emit(state.copyWith(
      pending: () => TransferOperation.submit,
      error: () => null,
      errorOrigin: () => null,
    ));
    try {
      final receipt = await _submitTransfer(
        request,
        pin: event.pin,
        idempotencyKey: key,
      );
      emit(state.copyWith(pending: () => null, receipt: () => receipt));
      _eventBus?.emit(AppEvent.balancesChanged);
    } catch (e) {
      // Keep the same key: a retry after a timeout must not double-debit.
      emit(state.copyWith(
        pending: () => null,
        error: () => e,
        errorOrigin: () => TransferOperation.submit,
      ));
    }
  }

  void _onStepBack(TransferStepBack event, Emitter<TransferState> emit) {
    if (state.pending != null) return;
    switch (state.step) {
      case TransferStep.review:
        emit(state.copyWith(
          step: TransferStep.amount,
          quote: () => null,
          idempotencyKey: () => null,
          error: () => null,
          errorOrigin: () => null,
        ));
      case TransferStep.amount:
        emit(state.copyWith(step: TransferStep.recipient));
      case TransferStep.recipient:
        emit(state.copyWith(step: TransferStep.source));
      case TransferStep.source:
        break;
    }
  }

  void _onErrorDismissed(
    TransferErrorDismissed event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(error: () => null, errorOrigin: () => null));
  }

  void _onReset(TransferReset event, Emitter<TransferState> emit) {
    emit(TransferState(
      accounts: state.accounts,
      accountsLoaded: state.accountsLoaded,
    ));
  }
}
