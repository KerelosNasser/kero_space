import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class CareerTab extends StatelessWidget {
  final FinanceLoaded state;

  const CareerTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Career Preparation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddTaskDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildKanbanColumn(context, 'TODO', state.careerTasks.where((t) => t.status == 'TODO').toList()),
                _buildKanbanColumn(context, 'IN_PROGRESS', state.careerTasks.where((t) => t.status == 'IN_PROGRESS').toList()),
                _buildKanbanColumn(context, 'DONE', state.careerTasks.where((t) => t.status == 'DONE').toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String title, List<CareerTask> tasks) {
    return DragTarget<CareerTask>(
      onAcceptWithDetails: (details) {
        if (details.data.status != title) {
          context.read<FinanceBloc>().add(UpdateCareerTaskStatusEvent(details.data.id, title));
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 250,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  '$title (${tasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Draggable<CareerTask>(
                      data: task,
                      feedback: SizedBox(
                        width: 230,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                          child: _buildTaskCard(context, task),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildTaskCard(context, task),
                      ),
                      child: _buildTaskCard(context, task),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, CareerTask task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showMoveDialog(context, task),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, CareerTask task) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Move "${task.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.status != 'TODO')
                ListTile(
                  title: const Text('Move to TODO'),
                  onTap: () {
                    context.read<FinanceBloc>().add(UpdateCareerTaskStatusEvent(task.id, 'TODO'));
                    Navigator.pop(dialogContext);
                  },
                ),
              if (task.status != 'IN_PROGRESS')
                ListTile(
                  title: const Text('Move to IN PROGRESS'),
                  onTap: () {
                    context.read<FinanceBloc>().add(UpdateCareerTaskStatusEvent(task.id, 'IN_PROGRESS'));
                    Navigator.pop(dialogContext);
                  },
                ),
              if (task.status != 'DONE')
                ListTile(
                  title: const Text('Move to DONE'),
                  onTap: () {
                    context.read<FinanceBloc>().add(UpdateCareerTaskStatusEvent(task.id, 'DONE'));
                    Navigator.pop(dialogContext);
                  },
                ),
              const Divider(),
              ListTile(
                title: const Text('Delete Task', style: TextStyle(color: AppTheme.accentRose)),
                leading: const Icon(Icons.delete, color: AppTheme.accentRose),
                onTap: () {
                  context.read<FinanceBloc>().add(DeleteCareerTaskEvent(task.id));
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Banking';
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Career Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Banking', child: Text('Banking')),
                      DropdownMenuItem(value: 'Tech Cert', child: Text('Tech Cert')),
                      DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final task = CareerTask()
                        ..title = titleController.text
                        ..description = descController.text
                        ..category = selectedCategory
                        ..status = 'TODO'
                        ..createdAt = DateTime.now();
                      
                      context.read<FinanceBloc>().add(AddCareerTaskEvent(task));
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
