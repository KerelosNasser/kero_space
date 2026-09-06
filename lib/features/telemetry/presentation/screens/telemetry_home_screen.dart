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
  @override
  State<TelemetryHomeScreen> createState() => _TelemetryHomeScreenState();
}

class _TelemetryHomeScreenState extends State<TelemetryHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (Icons.phone_android, 'Overview'),
    (Icons.grid_view, 'Heatmap'),
    (Icons.shield, 'Resistance'),
    (Icons.block, 'Blacklist'),
    (Icons.touch_app, 'Clicks'),
    (Icons.tune, 'Control'),
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
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Telemetry',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: colors.domainTelemetry,
          labelColor: colors.domainTelemetry,
          unselectedLabelColor: colors.textSecondary,
          tabs: _tabs
              .map(
                (t) => Tab(
                  icon: Icon(t.$1, size: 20),
                  text: t.$2,
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
    );
  }
}
