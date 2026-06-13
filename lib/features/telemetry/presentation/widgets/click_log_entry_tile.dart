import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/telemetry/data/models/telemetry_collections.dart';

class ClickLogEntryTile extends StatelessWidget {
  final TelemetryEvent event;
  const ClickLogEntryTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    try { data = jsonDecode(event.dataJson) as Map<String, dynamic>; } catch (_) {}
    final pkg = (data['packageName'] as String? ?? 'unknown').split('.').last;
    final viewId = data['viewId'] as String? ?? '';
    final time = '${event.timestamp.hour.toString().padLeft(2,'0')}:${event.timestamp.minute.toString().padLeft(2,'0')}';
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.touch_app, color: AppTheme.accentCyan, size: 18),
      ),
      title: Text(pkg, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: viewId.isNotEmpty
          ? Text(viewId, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(time, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
    );
  }
}
