import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/church_bloc.dart';
import '../data/models/ministry_task.dart';

class MinistryKanbanScreen extends StatefulWidget {
  const MinistryKanbanScreen({Key? key}) : super(key: key);

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
      backgroundColor: Colors.black, // --bg-primary
      appBar: AppBar(
        title: const Text('Ministry Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<ChurchBloc, ChurchState>(
        builder: (context, state) {
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
        backgroundColor: const Color(0xFFBF5AF2), // --accent-violet
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
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
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  color: const Color(0xFF1C1C1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(task.title, style: const TextStyle(color: Colors.white)),
                    subtitle: task.description != null ? Text(task.description!, style: const TextStyle(color: Colors.grey)) : null,
                    trailing: DropdownButton<MinistryTaskStatus>(
                      dropdownColor: const Color(0xFF2C2C2E),
                      value: task.status,
                      items: MinistryTaskStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.name, style: const TextStyle(color: Colors.white)),
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
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('New Task', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Title', hintStyle: TextStyle(color: Colors.grey)),
              ),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Description', hintStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBF5AF2)),
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
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
