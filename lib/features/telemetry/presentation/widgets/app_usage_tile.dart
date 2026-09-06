import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:installed_apps/app_info.dart';

class AppUsageTile extends StatelessWidget {
  final AppInfo app;
  final int? foregroundMs;
  final bool isBlacklisted;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const AppUsageTile({
    super.key, required this.app, this.foregroundMs,
    required this.isBlacklisted, required this.onAdd, required this.onRemove,
  });

  String _fmt(int ms) {
    final h = ms ~/ 3600000; final m = (ms % 3600000) ~/ 60000;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final icon = app.icon;
    return ListTile(
      leading: icon != null
          ? Image.memory(icon, width: 40, height: 40)
          : Icon(Icons.android, color: colors.domainTelemetry),
      title: Text(
        app.name,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: foregroundMs != null && foregroundMs! > 0
          ? Text(
              'Used ${_fmt(foregroundMs!)} today',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
            )
          : null,
      trailing: isBlacklisted
          ? IconButton(
              icon: Icon(Icons.remove_circle_outline, color: colors.accentError),
              onPressed: onRemove,
              tooltip: 'Remove rule',
            )
          : IconButton(
              icon: Icon(Icons.add_circle_outline, color: colors.domainTelemetry),
              onPressed: onAdd,
              tooltip: 'Add rule',
            ),
    );
  }
}
