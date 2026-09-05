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

  Color _getActiveColor(BuildContext context, int index) {
    final colors = context.appColors;
    switch (index) {
      case 0:
        return colors.accentPrimary;
      case 1:
        return colors.domainProductivity;
      case 2:
        return colors.domainHealth;
      case 3:
        return colors.domainFinance;
      case 4:
        return colors.domainChurch;
      case 5:
        return colors.domainTelemetry;
      default:
        return colors.accentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getActiveColor(context, currentIndex);
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: context.appColors.bgBase,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(color: activeColor),
      selectedLabelTextStyle: TextStyle(color: activeColor, fontWeight: FontWeight.w600),
      unselectedIconTheme: IconThemeData(color: context.appColors.textDisabled),
      unselectedLabelTextStyle: TextStyle(color: context.appColors.textDisabled),
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
