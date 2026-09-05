import 'package:flutter/material.dart';

enum AppNavStyle {
  commandCapsule,
  threePillars,
  floatingIsland,
  bentoHub,
  classicBar,
}

extension AppNavStyleDetails on AppNavStyle {
  String get displayName {
    switch (this) {
      case AppNavStyle.commandCapsule:
        return 'Command Capsule';
      case AppNavStyle.threePillars:
        return 'Three-Pillar Triad';
      case AppNavStyle.floatingIsland:
        return 'Floating Island Dock';
      case AppNavStyle.bentoHub:
        return 'Bento Control Hub';
      case AppNavStyle.classicBar:
        return 'Classic 6-Tab Bar';
    }
  }

  String get tagline {
    switch (this) {
      case AppNavStyle.commandCapsule:
        return '3-slot bar with center ⌘ Raycast-style command palette & app drawer.';
      case AppNavStyle.threePillars:
        return 'Grouped into Home, Life OS, and System & Spirit with sub-switchers.';
      case AppNavStyle.floatingIsland:
        return 'Minimalist floating dock with dynamic active domain pill.';
      case AppNavStyle.bentoHub:
        return 'Glanceable 2x3 bento launcher with live telemetry & routine stats.';
      case AppNavStyle.classicBar:
        return 'Traditional horizontal bar showing all 6 module icons simultaneously.';
    }
  }

  String get tag {
    switch (this) {
      case AppNavStyle.commandCapsule:
        return 'RECOMMENDED';
      case AppNavStyle.threePillars:
        return 'HIERARCHICAL';
      case AppNavStyle.floatingIsland:
        return 'FLOATING';
      case AppNavStyle.bentoHub:
        return 'CONTROL HUB';
      case AppNavStyle.classicBar:
        return 'LEGACY';
    }
  }

  IconData get icon {
    switch (this) {
      case AppNavStyle.commandCapsule:
        return Icons.terminal_rounded;
      case AppNavStyle.threePillars:
        return Icons.view_column_rounded;
      case AppNavStyle.floatingIsland:
        return Icons.layers_outlined;
      case AppNavStyle.bentoHub:
        return Icons.dashboard_customize_outlined;
      case AppNavStyle.classicBar:
        return Icons.table_rows_rounded;
    }
  }
}
