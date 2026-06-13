import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import '../../data/models/blocker_stat.dart';

class ResistanceRateCard extends StatelessWidget {
  final BlockerStat stat;
  const ResistanceRateCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final pct = (stat.resistanceRate * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stat.packageName.split('.').last, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(children: [
          Text('$pct%', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppTheme.accentMint)),
          const SizedBox(width: 12),
          Expanded(child: Text(
            'You resisted the urge $pct% of the time',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary),
          )),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: stat.resistanceRate, backgroundColor: AppTheme.bgElevated,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentMint),
          minHeight: 6, borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 6),
        Text('${stat.blockedAttempts} blocked · ${stat.grantedOverrides} overridden',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
      ]),
    );
  }
}
