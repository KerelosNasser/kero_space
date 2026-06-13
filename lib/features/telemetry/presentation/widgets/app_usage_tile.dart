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
    final icon = app.icon;
    return ListTile(
      leading: icon != null
          ? Image.memory(icon, width: 40, height: 40)
          : const Icon(Icons.android, color: AppTheme.accentCyan),
      title: Text(app.name, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: foregroundMs != null && foregroundMs! > 0
          ? Text('Used ${_fmt(foregroundMs!)} today',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary))
          : null,
      trailing: isBlacklisted
          ? IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accentRose), onPressed: onRemove)
          : IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentCyan), onPressed: onAdd),
    );
  }
}
