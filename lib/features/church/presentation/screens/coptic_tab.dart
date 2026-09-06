import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';
import '../bloc/coptic_bloc.dart';
import '../widgets/church_skeleton.dart';
import '../../data/models/coptic_day_info.dart';

class CopticTab extends StatelessWidget {
  const CopticTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CopticBloc, CopticState>(
      builder: (context, state) {
        if (state is CopticLoading || state is CopticInitial) {
          return const ChurchSkeleton();
        }
        if (state is CopticError) {
          return InlineErrorWidget(
            message: state.message,
            onRetry: () => context.read<CopticBloc>().add(LoadCopticData()),
          );
        }
        if (state is CopticLoaded) {
          final info = state.dayInfo;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _HeaderCard(info: info),
                ),
              ),
              if (info.feastName != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _FeastCard(info: info),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _ReadingsCard(
                      info: info, passageTexts: state.passageTexts),
                ),
              ),
              if (info.upcomingFeasts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child:
                        _UpcomingFeastsCard(feasts: info.upcomingFeasts),
                  ),
                ),
              if (info.fastStatus != FastingStatus.none)
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _FastStatusCard(info: info),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Header Card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final CopticDayInfo info;
  const _HeaderCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fastColor = info.fastStatus == FastingStatus.strict
        ? colors.accentError
        : info.fastStatus == FastingStatus.fishAllowed
            ? colors.accentSuccess
            : colors.accentPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.domainChurch.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.calendar_month,
                color: colors.domainChurch, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info.copticDay} ${info.monthName} ${info.copticYear} AM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                if (info.seasonName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    info.seasonName!,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fastColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              info.fastStatus == FastingStatus.none ? 'No Fast' : 'Fasting',
              style: TextStyle(
                  color: fastColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feast Card ────────────────────────────────────────────────────────────────

class _FeastCard extends StatelessWidget {
  final CopticDayInfo info;
  const _FeastCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: colors.accentWarning.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.feastName!,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.accentWarning,
                  ),
                ),
              ),
            ],
          ),
          if (info.feastDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              info.feastDescription!,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Readings Card ─────────────────────────────────────────────────────────────

class _ReadingsCard extends StatelessWidget {
  final CopticDayInfo info;
  final Map<String, String?> passageTexts;
  const _ReadingsCard(
      {required this.info, required this.passageTexts});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (info.readings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Readings",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...info.readings.map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Opening ${ref.displayName}...')),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book,
                            color: colors.accentSecondary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ref.displayName,
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: colors.textDisabled),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Upcoming Feasts Card ──────────────────────────────────────────────────────

class _UpcomingFeastsCard extends StatelessWidget {
  final List<UpcomingFeast> feasts;
  const _UpcomingFeastsCard({required this.feasts});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Upcoming Feasts',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: feasts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final feast = feasts[index];
              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feast.isMajor
                      ? colors.accentWarning.withValues(alpha: 0.10)
                      : colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: feast.isMajor
                      ? Border.all(
                          color:
                              colors.accentWarning.withValues(alpha: 0.30))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feast.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${feast.daysRemaining}d',
                        style: TextStyle(
                          color: colors.accentSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Fast Status Card ──────────────────────────────────────────────────────────

class _FastStatusCard extends StatelessWidget {
  final CopticDayInfo info;
  const _FastStatusCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isStrict = info.fastStatus == FastingStatus.strict;
    final statusColor = isStrict ? colors.accentError : colors.accentSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isStrict ? Icons.block : Icons.check_circle_outline,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Text(
            isStrict
                ? 'Strict Fast Today'
                : 'Fast Day — Fish Allowed',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
