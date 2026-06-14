import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';
import 'package:kero_space/features/church/presentation/screens/attendance_screen.dart';
import 'package:kero_space/features/church/presentation/screens/ministry_kanban_screen.dart';
import 'package:kero_space/features/church/presentation/screens/confession_auth_screen.dart';

class ChurchScreen extends StatelessWidget {
  const ChurchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Church'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Attendance"),
              Tab(text: "Ministry"),
              Tab(text: "Confession"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AttendanceScreen(),
            MinistryKanbanScreen(),
            ConfessionAuthScreen(),
          ],
        ),
      ),
    );
  }
}
