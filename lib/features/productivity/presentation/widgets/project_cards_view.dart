import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../../data/services/ai_service.dart';

class ProjectCardsView extends StatefulWidget {
  final List<Task> allTasks;

  const ProjectCardsView({super.key, required this.allTasks});

  @override
  State<ProjectCardsView> createState() => _ProjectCardsViewState();
}

class _ProjectCardsViewState extends State<ProjectCardsView> {
  final TextEditingController _aiProjectController = TextEditingController();
  final AIService _aiService = AIService();
  bool _isGenerating = false;

  void _generateProject() async {
    final title = _aiProjectController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final subtasks = await _aiService.breakdownProject(title);
      
      // We dispatch an event to the BLoC to create the project AND its subtasks
      // Note: This requires the ProductivityBloc to have a specific event for this.
      // For this implementation, we will dispatch them sequentially or rely on a new event.
      context.read<ProductivityBloc>().add(ProductivityEvent.createProjectWithSubtasks(title, subtasks));
      
      _aiProjectController.clear();
    } catch (e) {
      debugPrint("Generation error: $e");
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.allTasks.where((t) => t.type == TaskType.project).toList();

    return Column(
      children: [
        // AI Lazy Creation Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                )
              ]
            ),
            child: TextField(
              controller: _aiProjectController,
              decoration: InputDecoration(
                hintText: 'Lazy? Type "Plan Vacation" and AI will build it.',
                prefixIcon: const Icon(Icons.auto_awesome, color: AppTheme.accentViolet),
                suffixIcon: _isGenerating 
                  ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.accentCyan),
                      onPressed: _generateProject,
                    ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onSubmitted: (_) => _generateProject(),
            ),
          ),
        ),

        // Grid of Kanban Project Cards
        if (projects.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text("No projects yet.", style: TextStyle(color: AppTheme.textSecondary)),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final subtasks = widget.allTasks.where((t) => t.parentId == project.id).toList();
                final completedCount = subtasks.where((t) => t.isCompleted).length;
                final progress = subtasks.isEmpty ? 0.0 : completedCount / subtasks.length;

                return GestureDetector(
                  onTap: () {
                    // Navigate to unified project screen
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.folder, color: AppTheme.accentGold),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textSecondary),
                              onPressed: () {
                                context.read<ProductivityBloc>().add(ProductivityEvent.deleteTask(project.id));
                              },
                            )
                          ],
                        ),
                        const Spacer(),
                        Text(
                          project.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${subtasks.length} tasks",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.2),
                          color: AppTheme.accentMint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
