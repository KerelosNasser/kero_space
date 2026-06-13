import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/platform/platform_guard.dart';
import 'adaptive_nav_rail.dart';
import 'adaptive_bottom_nav.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // If the device is desktop or the screen is wide enough, use the side nav rail
    bool useDesktopNav = isDesktop || MediaQuery.sizeOf(context).width >= 800;

    if (useDesktopNav) {
      return Scaffold(
        body: Row(
          children: [
            AdaptiveNavRail(
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => _goBranch(i),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AdaptiveBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => _goBranch(i),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
