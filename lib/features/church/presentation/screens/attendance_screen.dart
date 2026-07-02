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
    return BlocConsumer<ChurchBloc, ChurchState>(
        listener: (context, state) {
          if (state.status == ChurchStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppTheme.accentRose),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ChurchStatus.loading &&
              state.attendances.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.accentViolet));
          }

          final currentStreak = state.currentStreak;

          return Padding(
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
                        const Text('CURRENT STREAK',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$currentStreak days',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 34,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentViolet,
                      ),
                      onPressed: () {
                        context.read<ChurchBloc>().add(MarkAttendanceEvent(
                            DateTime.now(), ServiceType.liturgy));
                      },
                      child: const Text('Mark Today',
                          style:
                              TextStyle(color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('ATTENDANCE GRID',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                AttendanceContributionGrid(
                    attendances: state.attendances),
                const SizedBox(height: 32),
                ListTile(
                  title: const Text('Retroactive Log',
                      style:
                          TextStyle(color: AppTheme.textPrimary)),
                  trailing: const Icon(Icons.calendar_today,
                      color: AppTheme.accentPrimary),
                  onTap: () async {
                    final bloc = context.read<ChurchBloc>();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      bloc.add(MarkAttendanceEvent(
                          date, ServiceType.liturgy));
                    }
                  },
                ),
              ],
            ),
          );
        },
      );

  }

  int _calculateStreak(List<MassAttendance> attendances) {
    if (attendances.isEmpty) return 0;
    
    // Sort descending
    final sorted = List<MassAttendance>.from(attendances)
      ..sort((a, b) => b.date.compareTo(a.date));
      
    int streak = 0;
    DateTime current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    for (var att in sorted) {
      final attDate = DateTime(att.date.year, att.date.month, att.date.day);
      final difference = current.difference(attDate).inDays;

      if (difference == 0) {
        if (streak == 0) streak = 1; // Count today if present
      } else if (difference == 1) {
        streak++;
        current = attDate;
      } else {
        break; // Streak broken
      }
    }
    return streak;
  }
}
