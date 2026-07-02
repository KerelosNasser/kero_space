import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/coptic_bloc.dart';
import 'coptic_tab.dart';
import 'attendance_screen.dart';
import 'ministry_kanban_screen.dart';
import 'confession_auth_screen.dart';

class ChurchScreen extends StatefulWidget {
  const ChurchScreen({super.key});

  @override
  State<ChurchScreen> createState() => _ChurchScreenState();
}

class _ChurchScreenState extends State<ChurchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<CopticBloc>().add(LoadCopticData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        title: const Text(
          'Church',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentViolet,
          labelColor: AppTheme.accentViolet,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Coptic'),
            Tab(text: 'Attendance'),
            Tab(text: 'Ministry'),
            Tab(text: 'Confession'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CopticTab(),
          AttendanceScreen(),
          MinistryKanbanScreen(),
          ConfessionAuthScreen(),
        ],
      ),
    );
  }
}
