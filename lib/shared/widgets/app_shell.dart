import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/platform/platform_guard.dart';
import '../../core/navigation/navigation_mode.dart';
import '../../core/navigation/navigation_cubit.dart';
import '../../core/navigation/navigation_state.dart';
import 'adaptive_nav_rail.dart';
import 'adaptive_bottom_nav.dart';
import 'navigation/command_capsule_nav.dart';
import 'navigation/three_pillars_nav.dart';
import 'navigation/floating_island_dock.dart';
import 'navigation/bento_hub_nav.dart';

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

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navState) {
        final isFloating = navState.mode == AppNavStyle.floatingIsland;

        return Scaffold(
          extendBody: isFloating,
          body: navigationShell,
          bottomNavigationBar: _buildBottomNav(navState.mode),
        );
      },
    );
  }

  Widget _buildBottomNav(AppNavStyle mode) {
    switch (mode) {
      case AppNavStyle.commandCapsule:
        return CommandCapsuleNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => _goBranch(i),
        );
      case AppNavStyle.threePillars:
        return ThreePillarsNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => _goBranch(i),
        );
      case AppNavStyle.floatingIsland:
        return FloatingIslandDock(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => _goBranch(i),
        );
      case AppNavStyle.bentoHub:
        return BentoHubNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => _goBranch(i),
        );
      case AppNavStyle.classicBar:
        return AdaptiveBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => _goBranch(i),
        );
    }
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
