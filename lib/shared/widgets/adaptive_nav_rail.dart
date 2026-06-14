import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class AdaptiveNavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdaptiveNavRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  Color _getActiveColor(int index) {
    switch (index) {
      case 0: return AppTheme.accentPrimary;
      case 1: return AppTheme.accentCyan;
      case 2: return AppTheme.accentMint;
      case 3: return AppTheme.accentGold;
      case 4: return AppTheme.accentViolet;
      case 5: return AppTheme.accentGold;
      default: return AppTheme.accentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(color: _getActiveColor(currentIndex)),
      selectedLabelTextStyle: TextStyle(color: _getActiveColor(currentIndex)),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.task_alt_outlined),
          selectedIcon: Icon(Icons.task_alt),
          label: Text('Tasks'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: Text('Health'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text('Finance'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.church_outlined),
          selectedIcon: Icon(Icons.church),
          label: Text('Church'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Telemetry'),
        ),
      ],
    );
  }
}
