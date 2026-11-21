import 'package:flutter/material.dart';

/// Navigation without a routing package: one root [Navigator].
///
/// * [AuthGate] decides the root screen (splash, lock, login or [MainShell])
///   from the sign-in state.
/// * Screens are opened with [AppNavigator.pushPage]; their widgets (with the
///   BLoCs they need) are built by `Pages` in `pages.dart`.
/// * The bottom-navigation tab is held in [mainTab].
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Bottom-navigation tabs of [MainShell], in display order.
enum MainTab { home, transactions, transfer, profile }

/// The selected bottom-navigation tab.
final ValueNotifier<MainTab> mainTab = ValueNotifier(MainTab.home);

/// Closes every pushed screen, back to the root chosen by [AuthGate].
void popToRoot() =>
    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);

extension AppNavigator on BuildContext {
  Future<T?> pushPage<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));

  /// Replaces the current screen with [page].
  Future<T?> replacePage<T>(Widget page) => Navigator.of(
    this,
  ).pushReplacement<T, Object?>(MaterialPageRoute(builder: (_) => page));

  void popPage<T>([T? result]) => Navigator.of(this).pop<T>(result);

  /// Closes every pushed screen and shows [tab] of the main shell.
  void showTab(MainTab tab) {
    popToRoot();
    mainTab.value = tab;
  }
}
