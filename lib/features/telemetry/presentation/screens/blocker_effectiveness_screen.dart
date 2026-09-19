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
    final colors = context.appColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<TelemetryBloc, TelemetryState>(
      builder: (context, state) {
        if (state.blockerStats.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: colors.accentSuccess, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No blocker events yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add apps to the blacklist to start tracking your resistance.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final totalBlocked = state.blockerStats.fold<int>(0, (sum, s) => sum + s.blockedAttempts);
        final totalDecisions = state.blockerStats.fold<int>(0, (sum, s) => sum + s.blockedAttempts + s.grantedOverrides);
        final overallResistance = totalDecisions > 0 ? (totalBlocked / totalDecisions * 100).round() : 0;
        final estimatedHoursSaved = (totalBlocked * 12) ~/ 60;
        final estimatedMinsSaved = (totalBlocked * 12) % 60;

        return SafeArea(
          top: false,
          bottom: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: bottomInset + 32,
                ),
                children: [
                  // Addiction Recovery Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.domainTelemetry.withValues(alpha: 0.22),
                          colors.accentPrimary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.domainTelemetry.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.offline_bolt_rounded, color: colors.domainTelemetry, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ADDICTION RECOVERY DASHBOARD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: colors.domainTelemetry,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    'Blocked Opens',
                                    '$totalBlocked',
                                    colors,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: colors.borderSubtle,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    'Resistance',
                                    '$overallResistance%',
                                    colors,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: colors.borderSubtle,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    'Time Saved',
                                    estimatedHoursSaved > 0
                                        ? '${estimatedHoursSaved}h ${estimatedMinsSaved}m'
                                        : '${estimatedMinsSaved}m',
                                    colors,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Resistance Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last 7 days — how well you resisted mindless scrolling',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...state.blockerStats.map((s) => ResistanceRateCard(stat: s)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String title, String value, AppThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
