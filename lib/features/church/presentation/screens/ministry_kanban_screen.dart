import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/church_bloc.dart';
import '../../data/models/ministry_task.dart';

class MinistryKanbanScreen extends StatefulWidget {
  const MinistryKanbanScreen({super.key});

  @override
  State<MinistryKanbanScreen> createState() => _MinistryKanbanScreenState();
}

class _MinistryKanbanScreenState extends State<MinistryKanbanScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChurchBloc>().add(LoadChurchData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Ministry Service', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.bgPrimary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: BlocConsumer<ChurchBloc, ChurchState>(
        listener: (context, state) {
          if (state.status == ChurchStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.accentRose),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ChurchStatus.loading && state.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet));
          }

          final todoTasks = state.tasks.where((t) => t.status == MinistryTaskStatus.todo).toList();
          final inProgressTasks = state.tasks.where((t) => t.status == MinistryTaskStatus.inProgress).toList();
          final doneTasks = state.tasks.where((t) => t.status == MinistryTaskStatus.done).toList();

          return PageView(
            children: [
              _buildKanbanColumn('To Do', todoTasks, MinistryTaskStatus.todo),
              _buildKanbanColumn('In Progress', inProgressTasks, MinistryTaskStatus.inProgress),
              _buildKanbanColumn('Done', doneTasks, MinistryTaskStatus.done),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentViolet,
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add, color: AppTheme.accentPrimary),
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<MinistryTask> tasks, MinistryTaskStatus columnStatus) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, color: AppTheme.textDisabled, size: 48),
                      const SizedBox(height: 8),
                      const Text('No tasks', style: TextStyle(color: AppTheme.textDisabled)),
                    ],
                  ),
                )
              : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  color: AppTheme.bgSurface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(task.title, style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: task.description != null ? Text(task.description!, style: const TextStyle(color: AppTheme.textSecondary)) : null,
                    trailing: DropdownButton<MinistryTaskStatus>(
                      dropdownColor: AppTheme.bgElevated,
                      value: task.status,
                      items: MinistryTaskStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.name, style: const TextStyle(color: AppTheme.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          final updatedTask = task..status = newStatus;
                          context.read<ChurchBloc>().add(UpdateServiceTaskEvent(updatedTask));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          title: const Text('New Task', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'Title', hintStyle: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextField(
                controller: descController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'Description', hintStyle: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentViolet),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final task = MinistryTask()
                    ..title = titleController.text
                    ..description = descController.text
                    ..status = MinistryTaskStatus.todo;
                  context.read<ChurchBloc>().add(UpdateServiceTaskEvent(task));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: AppTheme.textPrimary)),
            ),
          ],
        );
      },
    );
  }
}
