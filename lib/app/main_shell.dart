import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';
import '../core/widgets/app_bottom_navigation.dart';
import 'navigation.dart';
import 'pages.dart';

/// Scaffold with the bottom navigation: Home, Transactions, Transfer, Profile.
///
/// Each tab is built the first time it is shown and then kept alive, so its
/// scroll position and state survive tab switches.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final Map<MainTab, Widget> _built = {};

  Widget _tab(MainTab tab) => _built.putIfAbsent(
    tab,
    () => switch (tab) {
      MainTab.home => Pages.home(),
      MainTab.transactions => Pages.transactions(),
      MainTab.transfer => Pages.transfer(),
      MainTab.profile => Pages.profile(),
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<MainTab>(
      valueListenable: mainTab,
      builder: (context, current, _) {
        _tab(current);
        return Scaffold(
          body: IndexedStack(
            index: current.index,
            children: [
              for (final tab in MainTab.values)
                _built[tab] ?? const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: current.index,
            onSelected: (index) => mainTab.value = MainTab.values[index],
            items: [
              AppNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: l10n.navHome,
              ),
              AppNavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: l10n.navTransactions,
              ),
              AppNavItem(
                icon: Icons.swap_horiz_outlined,
                selectedIcon: Icons.swap_horiz_rounded,
                label: l10n.navTransfer,
              ),
              AppNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: l10n.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
