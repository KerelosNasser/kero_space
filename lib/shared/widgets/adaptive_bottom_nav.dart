import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class AdaptiveBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdaptiveBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _getActiveColor(currentIndex),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt_outlined),
          activeIcon: Icon(Icons.task_alt),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite_rounded),
          label: 'Health',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Finance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.church_outlined),
          activeIcon: Icon(Icons.church),
          label: 'Church',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Telemetry',
        ),
      ],
    );
  }
}
