import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';

import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/app_usage_tile.dart';
import '../widgets/rule_configuration_sheet.dart';

class BlacklistManagementScreen extends StatefulWidget {
  const BlacklistManagementScreen({super.key});
  @override State<BlacklistManagementScreen> createState() => _State();
}

class _State extends State<BlacklistManagementScreen> {
  List<AppInfo> _apps = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<TelemetryBloc>().add(const LoadBlacklist());
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
    if (mounted) setState(() { _apps = apps; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      final blacklisted = state.blacklistRules.map((r) => r.packageName).toSet();
      final usageMap = {for (final r in state.todayTopApps) r.packageName: r.foregroundMs};
      final filtered = _apps
          .where((a) => _query.isEmpty || a.name.toLowerCase().contains(_query.toLowerCase()))
          .toList()
        ..sort((a, b) => (usageMap[b.packageName] ?? 0).compareTo(usageMap[a.packageName] ?? 0));

      final colors = context.appColors;

      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          title: Text('Configure App Blockers', style: TextStyle(color: colors.textPrimary)),
          backgroundColor: colors.bgBase,
          iconTheme: IconThemeData(color: colors.textPrimary),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          _loading
              ? Expanded(child: Center(child: CircularProgressIndicator(color: colors.domainTelemetry)))
              : filtered.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apps, size: 56, color: colors.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              _query.isEmpty ? 'No installed apps detected' : 'No apps matching "$_query"',
                              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final app = filtered[i];
                          return AppUsageTile(
                            app: app,
                            foregroundMs: usageMap[app.packageName],
                            isBlacklisted: blacklisted.contains(app.packageName),
                            onAdd: () async {
                              final rule = await RuleConfigurationSheet.show(context, app.packageName);
                              if (rule != null && context.mounted) {
                                context.read<TelemetryBloc>().add(AddBlacklistRule(rule));
                              }
                            },
                            onRemove: () => context.read<TelemetryBloc>().add(RemoveBlacklistRule(app.packageName)),
                          );
                        },
                      ),
                    ),
        ]),
      );
    });
  }
}
