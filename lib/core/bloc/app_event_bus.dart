import 'dart:async';

/// Cross-feature notifications (e.g. "balances changed after a transfer")
/// so features can refresh without depending on each other's BLoCs.
enum AppEvent { balancesChanged, profileChanged }

class AppEventBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
