import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';

class TaskTreeView extends StatefulWidget {
  final List<Task> allTasks;

  const TaskTreeView({super.key, required this.allTasks});

  @override
  State<TaskTreeView> createState() => _TaskTreeViewState();
}

class _TaskTreeViewState extends State<TaskTreeView> {
  late final TreeController<Task> treeController;

  @override
  void initState() {
    super.initState();
    treeController = TreeController<Task>(
      roots: widget.allTasks.where((t) => t.type == TaskType.project).toList(),
      childrenProvider: (Task task) {
        return widget.allTasks.where((t) => t.parentId == task.id).toList();
      },
    );
  }

  @override
  void didUpdateWidget(covariant TaskTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    treeController.roots = widget.allTasks.where((t) => t.type == TaskType.project).toList();
  }

  @override
  void dispose() {
    treeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allTasks.isEmpty) {
      return const Center(child: Text("No projects yet. Create one!"));
    }

    return TreeView<Task>(
      treeController: treeController,
      nodeBuilder: (BuildContext context, TreeEntry<Task> entry) {
        return TreeItemWidget(
          entry: entry,
          treeController: treeController,
          onComplete: () {
            context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(entry.node.id));
          },
          onDelete: () {
            context.read<ProductivityBloc>().add(ProductivityEvent.deleteTask(entry.node.id));
          },
        );
      },
    );
  }
}

class TreeItemWidget extends StatelessWidget {
  final TreeEntry<Task> entry;
  final TreeController<Task> treeController;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const TreeItemWidget({
    super.key,
    required this.entry,
    required this.treeController,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => treeController.toggleExpansion(entry.node),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(width: entry.level * 20.0), // Indentation
            IconButton(
              icon: Icon(
                entry.hasChildren ? (entry.isExpanded ? Icons.folder_open : Icons.folder) : Icons.insert_drive_file,
              ),
              onPressed: entry.hasChildren ? () => treeController.toggleExpansion(entry.node) : null,
            ),
            Expanded(
              child: Text(
                entry.node.title,
                style: TextStyle(
                  fontWeight: entry.node.type == TaskType.project ? FontWeight.bold : FontWeight.normal,
                  decoration: entry.node.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (!entry.node.isCompleted)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: onComplete,
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
