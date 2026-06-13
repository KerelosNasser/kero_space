import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_state.dart';
import '../bloc/telemetry_bloc.dart';
import '../widgets/resistance_rate_card.dart';

class BlockerEffectivenessScreen extends StatelessWidget {
  const BlockerEffectivenessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      if (state.blockerStats.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.shield_outlined, color: AppTheme.accentMint, size: 64),
          const SizedBox(height: 16),
          Text('No blocker events yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Add apps to the blacklist to start tracking.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
        ]));
      }
      return ListView(padding: const EdgeInsets.all(16), children: [
        Text('Resistance Report', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Last 7 days — how well you resisted mindless scrolling',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        ...state.blockerStats.map((s) => ResistanceRateCard(stat: s)),
      ]);
    });
  }
}
