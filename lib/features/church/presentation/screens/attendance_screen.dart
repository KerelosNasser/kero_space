import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/church_bloc.dart';
import '../data/models/mass_attendance.dart';
import 'widgets/attendance_contribution_grid.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

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
    return Scaffold(
      backgroundColor: Colors.black, // --bg-primary
      appBar: AppBar(
        title: const Text('Mass Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<ChurchBloc, ChurchState>(
        builder: (context, state) {
          int currentStreak = _calculateStreak(state.attendances);

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
                        const Text('CURRENT STREAK', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$currentStreak days', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBF5AF2),
                      ),
                      onPressed: () {
                        context.read<ChurchBloc>().add(MarkAttendanceEvent(DateTime.now(), AttendanceType.liturgy));
                      },
                      child: const Text('Mark Today', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('ATTENDANCE GRID', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 8),
                AttendanceContributionGrid(attendances: state.attendances),
                const SizedBox(height: 32),
                ListTile(
                  title: const Text('Retroactive Log', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.calendar_today, color: Colors.white),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null && mounted) {
                      context.read<ChurchBloc>().add(MarkAttendanceEvent(date, AttendanceType.liturgy));
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
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
