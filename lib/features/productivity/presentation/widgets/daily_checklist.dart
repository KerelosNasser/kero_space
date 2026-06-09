import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';

class DailyChecklist extends StatelessWidget {
  final List<Task> tasks;

  const DailyChecklist({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks due today. Great job!"));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (val) {
              if (val == true) {
                context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(task.id));
              } else {
                // If we need un-complete, we'd add an event for it.
              }
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: task.description != null ? Text(task.description!) : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              context.read<ProductivityBloc>().add(ProductivityEvent.deleteTask(task.id));
            },
          ),
        );
      },
    );
  }
}
