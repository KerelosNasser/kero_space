import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/agent_toggle_card.dart';
import '../widgets/bypass_puzzle_dialog.dart';

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
                onToggle: (v) => context.read<TelemetryBloc>().add(ToggleAgent(id, v)),
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
