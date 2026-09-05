import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kero_space/core/app_theme.dart';

import 'package:kero_space/features/productivity/presentation/bloc/productivity_bloc.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    final colors = context.appColors;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              title: const Text(
                'Trobio',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              background: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(16),
                child: Text(
                  dateStr,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'TODAY\'S FOCUS',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _buildProductivityCard(context),
                const SizedBox(height: 24),

                Text(
                  'HEALTH & TELEMETRY',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildHealthCard(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTelemetryCard(context)),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'WEALTH & SPIRITUALITY',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFinanceCard(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildChurchCard(context)),
                  ],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityCard(BuildContext context) {
    return BlocBuilder<ProductivityBloc, ProductivityState>(
      builder: (context, state) {
        String subtitle = 'Loading tasks...';
        String metric = '--';

        state.maybeWhen(
          loaded: (allTasks, dailyChecklist, allNotes) {
            final pending = dailyChecklist.where((t) => !t.isCompleted).length;
            subtitle = '$pending tasks pending';
            metric = pending > 0
                ? dailyChecklist
                      .firstWhere(
                        (t) => !t.isCompleted,
                        orElse: () => dailyChecklist.first,
                      )
                      .title
                : 'All Done!';
          },
          orElse: () {},
        );

        return _buildSnapshotCard(
          context: context,
          domainLabel: subtitle,
          heroMetric: metric,
          accentColor: context.appColors.domainProductivity,
          route: '/productivity',
          heroTag: 'hero-productivity',
        );
      },
    );
  }

  Widget _buildHealthCard(BuildContext context) {
    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        return _buildSnapshotCard(
          context: context,
          domainLabel: 'HEALTH RING',
          heroMetric: '${state.steps.toInt()} steps',
          accentColor: context.appColors.domainHealth,
          route: '/health',
          heroTag: 'hero-health',
        );
      },
    );
  }

  Widget _buildTelemetryCard(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(
      builder: (context, state) {
        final hours = state.todayScreenTimeMs / (1000 * 60 * 60);
        return _buildSnapshotCard(
          context: context,
          domainLabel: 'SCREEN TIME',
          heroMetric: '${hours.toStringAsFixed(1)} h',
          accentColor: context.appColors.domainTelemetry,
          route: '/telemetry',
          heroTag: 'hero-telemetry',
        );
      },
    );
  }

  Widget _buildFinanceCard(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        String metric = '--';
        if (state is FinanceLoaded) {
          metric = 'EGP ${state.totalIncome.toInt()}';
        }
        return _buildSnapshotCard(
          context: context,
          domainLabel: 'EARNINGS THIS MONTH',
          heroMetric: metric,
          accentColor: context.appColors.domainFinance,
          route: '/finance',
          heroTag: 'hero-finance',
        );
      },
    );
  }

  Widget _buildChurchCard(BuildContext context) {
    return BlocBuilder<ChurchBloc, ChurchState>(
      builder: (context, state) {
        final streak = state.currentStreak;
        final today = DateTime.now();
        final todayMarked = state.attendances.any(
          (a) =>
              a.date.year == today.year &&
              a.date.month == today.month &&
              a.date.day == today.day,
        );
        return _buildSnapshotCard(
          context: context,
          domainLabel: todayMarked ? 'MASS TODAY ✓' : 'MASS STREAK',
          heroMetric: '${streak}d streak',
          accentColor: context.appColors.domainChurch,
          route: '/church',
          heroTag: 'hero-church',
        );
      },
    );
  }

  Widget _buildSnapshotCard({
    required BuildContext context,
    required String domainLabel,
    required String heroMetric,
    required Color accentColor,
    required String route,
    required String heroTag,
  }) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: accentColor, width: 3.5),
              top: BorderSide(color: colors.borderSubtle, width: 1),
              right: BorderSide(color: colors.borderSubtle, width: 1),
              bottom: BorderSide(color: colors.borderSubtle, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                domainLabel,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                heroMetric,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
