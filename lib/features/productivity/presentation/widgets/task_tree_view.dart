import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';
import 'package:kero_space/core/app_theme.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 64,
                color: context.appColors.domainProductivity.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                "No task tree hierarchy",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Projects and subtasks will display as an interactive hierarchy here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TreeView<Task>(
      treeController: treeController,
      nodeBuilder: (BuildContext context, TreeEntry<Task> entry) {
        return TreeItemWidget(
          entry: entry,
          treeController: treeController,
          onToggleComplete: () {
            if (entry.node.isCompleted) {
              context.read<ProductivityBloc>().add(ProductivityEvent.uncompleteTask(entry.node.id));
            } else {
              context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(entry.node.id));
            }
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Task'),
                content: Text('Delete "${entry.node.title}"? Any subtasks will also be affected.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              context.read<ProductivityBloc>().add(ProductivityEvent.deleteTask(entry.node.id));
            }
          },
        );
      },
    );
  }
}

class TreeItemWidget extends StatelessWidget {
  final TreeEntry<Task> entry;
  final TreeController<Task> treeController;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const TreeItemWidget({
    super.key,
    required this.entry,
    required this.treeController,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
                  color: entry.node.isCompleted ? colors.textSecondary : null,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                entry.node.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: entry.node.isCompleted ? colors.accentSuccess : colors.textSecondary,
              ),
              tooltip: entry.node.isCompleted ? 'Mark Incomplete' : 'Complete',
              onPressed: onToggleComplete,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.accentDanger),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
