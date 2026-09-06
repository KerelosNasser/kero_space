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
  MinistryTaskStatus _selectedColumn = MinistryTaskStatus.todo;

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
        if (state.status == ChurchStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colors.accentDanger),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ChurchStatus.loading && state.tasks.isEmpty) {
          return Center(
              child: CircularProgressIndicator(
                  color: colors.domainChurch));
        }

        final todoTasks = state.tasks
            .where((t) => t.status == MinistryTaskStatus.todo)
            .toList();
        final inProgressTasks = state.tasks
            .where((t) => t.status == MinistryTaskStatus.inProgress)
            .toList();
        final doneTasks = state.tasks
            .where((t) => t.status == MinistryTaskStatus.done)
            .toList();

        List<MinistryTask> currentTasks;
        String columnTitle;
        switch (_selectedColumn) {
          case MinistryTaskStatus.todo:
            currentTasks = todoTasks;
            columnTitle = 'To Do';
            break;
          case MinistryTaskStatus.inProgress:
            currentTasks = inProgressTasks;
            columnTitle = 'In Progress';
            break;
          case MinistryTaskStatus.done:
            currentTasks = doneTasks;
            columnTitle = 'Done';
            break;
        }

        return Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SegmentedButton<MinistryTaskStatus>(
                    segments: [
                      ButtonSegment(
                        value: MinistryTaskStatus.todo,
                        label: Text('To Do (${todoTasks.length})'),
                      ),
                      ButtonSegment(
                        value: MinistryTaskStatus.inProgress,
                        label: Text('Doing (${inProgressTasks.length})'),
                      ),
                      ButtonSegment(
                        value: MinistryTaskStatus.done,
                        label: Text('Done (${doneTasks.length})'),
                      ),
                    ],
                    selected: {_selectedColumn},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedColumn = selection.first);
                    },
                  ),
                ),
                Expanded(
                  child: _buildKanbanColumn(context, columnTitle, currentTasks, _selectedColumn),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: colors.domainChurch,
                onPressed: () => _showAddTaskDialog(context),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKanbanColumn(
      BuildContext context, String title, List<MinistryTask> tasks, MinistryTaskStatus columnStatus) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              color: colors.domainChurch.withValues(alpha: 0.4), size: 56),
                          const SizedBox(height: 12),
                          Text('No tasks in this column',
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Tap + to create a new ministry task.',
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        color: colors.bgSurface,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.borderSubtle),
                        ),
                        child: ListTile(
                          title: Text(task.title,
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          subtitle: task.description != null
                              ? Text(task.description!,
                                  style: TextStyle(
                                      color: colors.textSecondary))
                              : null,
                          trailing: DropdownButton<MinistryTaskStatus>(
                            dropdownColor: colors.bgSurface,
                            value: task.status,
                            items: MinistryTaskStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.name,
                                    style: TextStyle(
                                        color: colors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                final updatedTask =
                                    task.copyWith(status: newStatus);
                                context.read<ChurchBloc>().add(
                                    UpdateServiceTaskEvent(updatedTask));
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
    final colors = context.appColors;
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.bgSurface,
          title: Text('New Task',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: colors.textSecondary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(color: colors.textSecondary)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: colors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: colors.domainChurch),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final task = MinistryTask()
                    ..title = titleController.text
                    ..description = descController.text
                    ..status = MinistryTaskStatus.todo
                    ..priority = 3;
                  context
                      .read<ChurchBloc>()
                      .add(AddTaskEvent(task));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
