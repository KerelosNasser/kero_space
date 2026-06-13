import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import 'screen_time_overview_screen.dart';
import 'unlock_heatmap_screen.dart';
import 'blocker_effectiveness_screen.dart';
import 'blacklist_management_screen.dart';
import 'click_log_browser_screen.dart';
import 'omniscient_control_center_screen.dart';

class TelemetryHomeScreen extends StatefulWidget {
  const TelemetryHomeScreen({super.key});
  @override State<TelemetryHomeScreen> createState() => _State();
}

class _State extends State<TelemetryHomeScreen> {
  int _idx = 0;

  static const _tabs = [
    (Icons.phone_android, 'Overview'),
    (Icons.grid_view,     'Heatmap'),
    (Icons.shield,        'Resistance'),
    (Icons.block,         'Blacklist'),
    (Icons.touch_app,     'Clicks'),
    (Icons.settings,      'Control'),
  ];

  static const _screens = [
    ScreenTimeOverviewScreen(),
    UnlockHeatmapScreen(),
    BlockerEffectivenessScreen(),
    BlacklistManagementScreen(),
    ClickLogBrowserScreen(),
    OmniscientControlCenterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        title: Text(_tabs[_idx].$2,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: _screens[_idx],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.bgSurface,
        indicatorColor: AppTheme.accentCyan.withValues(alpha: 0.2),
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: _tabs.map((t) => NavigationDestination(
          icon: Icon(t.$1, color: AppTheme.textSecondary),
          selectedIcon: Icon(t.$1, color: AppTheme.accentCyan),
          label: t.$2,
        )).toList(),
      ),
    );
  }
}
