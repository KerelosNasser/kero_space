import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/agent_toggle_card.dart';
import '../widgets/bypass_puzzle_dialog.dart';
import 'package:kero_space/core/di/injection.dart';
import 'package:kero_space/core/permissions/permission_item.dart';
import 'package:kero_space/core/permissions/permission_tile.dart';
import 'package:kero_space/core/permissions/permission_repository.dart';

class OmniscientControlCenterScreen extends StatefulWidget {
  const OmniscientControlCenterScreen({super.key});
  @override State<OmniscientControlCenterScreen> createState() => _State();
}

class _State extends State<OmniscientControlCenterScreen> {
  static const _agents = [
    ('accessibility', 'Scrolling Blocker', Icons.block, 'Intercepts blacklisted app launches'),
    ('usage_guard',   'Usage Guard',       Icons.bar_chart, 'Tracks foreground time every 15 min'),
    ('screen_event',  'Screen Monitor',    Icons.phone_android, 'Logs wake, sleep & unlock events'),
    ('wake_word',     'Wake Word',         Icons.mic, 'Listens for "Hey Kero" — fully offline'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TelemetryBloc>().add(const RefreshAgentStatuses()));
  }

  Future<void> _handleToggle(BuildContext context, String id, bool v) async {
    if (!v) {
      context.read<TelemetryBloc>().add(ToggleAgent(id, v));
      return;
    }
    
    final repo = getIt<PermissionRepository>();
    PermissionItem? missingItem;

    if (id == 'wake_word') {
      if (!await repo.hasRecordAudio()) {
        missingItem = PermissionItem(
          title: 'Microphone',
          description: 'Required for the offline Wake Word detection. Audio never leaves your device.',
          icon: Icons.mic,
          check: repo.hasRecordAudio,
          request: repo.requestRecordAudio,
        );
      }
    } else if (id == 'accessibility') {
      if (!await repo.hasAccessibilityService()) {
        missingItem = PermissionItem(
          title: 'Accessibility Service',
          description: 'Required for the Mindless Scrolling Blocker overlay and Click Logger.',
          icon: Icons.accessibility_new,
          check: repo.hasAccessibilityService,
          request: repo.openAccessibilitySettings,
        );
      }
    } else if (id == 'usage_guard') {
      if (!await repo.hasUsageStats()) {
        missingItem = PermissionItem(
          title: 'App Usage Access',
          description: 'Allows querying daily app usage stats to enforce blocker quotas.',
          icon: Icons.assessment_outlined,
          check: repo.hasUsageStats,
          request: repo.openUsageStatsSettings,
        );
      }
    } else if (id == 'screen_event') {
      if (!await repo.hasBatteryOptimizationExemption()) {
         missingItem = PermissionItem(
          title: 'Ignore Battery Optimizations',
          description: 'Prevents the OS from killing background monitoring agents.',
          icon: Icons.battery_saver,
          check: repo.hasBatteryOptimizationExemption,
          request: repo.openBatteryOptimizationSettings,
        );
      }
    }

    if (missingItem != null && context.mounted) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.bgPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _PermissionBottomSheet(item: missingItem!),
      );

      final granted = await missingItem.check();
      if (!granted && context.mounted) {
         context.read<TelemetryBloc>().add(const RefreshAgentStatuses());
         return;
      }
    }

    if (context.mounted) {
      context.read<TelemetryBloc>().add(ToggleAgent(id, v));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Agent Control Center', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Toggle agents and configure blocker rules.',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
            itemCount: _agents.length,
            itemBuilder: (context, i) {
              final (id, label, icon, summary) = _agents[i];
              return AgentToggleCard(
                agentId: id, label: label, icon: icon, statusSummary: summary,
                isEnabled: state.agentStatuses[id] ?? false,
                onToggle: (v) => _handleToggle(context, id, v),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Emergency Override', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRose),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bypass Blocker', style: Theme.of(context).textTheme.headlineMedium),
                Text('Solve a math puzzle to bypass. Event is logged.',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
              ])),
              TextButton(
                onPressed: () async {
                  final solved = await BypassPuzzleDialog.show(context);
                  if (!context.mounted) return;
                  if (solved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bypass granted. Logged.')));
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentRose),
                child: const Text('Override'),
              ),
            ]),
          ),
        ]),
      );
    });
  }
}

class _PermissionBottomSheet extends StatefulWidget {
  final PermissionItem item;
  const _PermissionBottomSheet({required this.item});

  @override
  State<_PermissionBottomSheet> createState() => _PermissionBottomSheetState();
}

class _PermissionBottomSheetState extends State<_PermissionBottomSheet> with WidgetsBindingObserver {
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    final granted = await widget.item.check();
    if (mounted) setState(() => _isGranted = granted);
    if (granted && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _request() async {
    await widget.item.request();
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Permission Required', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          PermissionTile(item: widget.item, isGranted: _isGranted, onRequest: _request),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
