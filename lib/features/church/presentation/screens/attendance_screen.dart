import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/church_bloc.dart';
import '../../data/models/mass_attendance.dart';
import '../widgets/attendance_contribution_grid.dart';
import 'package:kero_space/core/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChurchBloc>().add(LoadChurchData());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocConsumer<ChurchBloc, ChurchState>(
      listener: (context, state) {
        if (state.status == ChurchStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.accentError,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ChurchStatus.loading && state.attendances.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: colors.domainChurch),
          );
        }

        final currentStreak = state.currentStreak;
        final now = DateTime.now();
        final isTodayMarked = state.attendances.any((a) =>
            a.date.year == now.year &&
            a.date.month == now.month &&
            a.date.day == now.day);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT STREAK',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentStreak days',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTodayMarked
                          ? colors.accentSuccess.withValues(alpha: 0.15)
                          : colors.domainChurch,
                      side: isTodayMarked ? BorderSide(color: colors.accentSuccess) : null,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (isTodayMarked) {
                        context.read<ChurchBloc>().add(
                          DeleteAttendanceEvent(now, ServiceType.liturgy),
                        );
                      } else {
                        context.read<ChurchBloc>().add(
                          MarkAttendanceEvent(now, ServiceType.liturgy),
                        );
                      }
                    },
                    icon: Icon(
                      isTodayMarked ? Icons.check_circle : Icons.add_circle_outline,
                      color: isTodayMarked ? colors.accentSuccess : Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      isTodayMarked ? 'Marked' : 'Mark Today',
                      style: TextStyle(
                        color: isTodayMarked ? colors.accentSuccess : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'ATTENDANCE GRID',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              AttendanceContributionGrid(attendances: state.attendances),
              const SizedBox(height: 24),
              Card(
                color: colors.bgElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.borderSubtle),
                ),
                child: ListTile(
                  title: Text(
                    'Retroactive Log / Toggle',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Tap to mark or unmark attendance for a specific date',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  trailing: Icon(Icons.calendar_today, color: colors.domainChurch),
                  onTap: () async {
                    final bloc = context.read<ChurchBloc>();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final isMarked = state.attendances.any((a) =>
                          a.date.year == date.year &&
                          a.date.month == date.month &&
                          a.date.day == date.day);
                      if (isMarked) {
                        bloc.add(DeleteAttendanceEvent(date, ServiceType.liturgy));
                      } else {
                        bloc.add(MarkAttendanceEvent(date, ServiceType.liturgy));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
