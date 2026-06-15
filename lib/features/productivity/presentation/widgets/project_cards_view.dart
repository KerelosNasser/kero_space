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

  void _generateProject([String? followUpAnswer]) async {
    final prompt = followUpAnswer ?? _aiProjectController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final response = await _aiService.breakdownProject(prompt);
      
      if (response is Map && response['type'] == 'clarification') {
        _showClarificationDialog(response['question']);
      } else if (response is Map && response['type'] == 'plan') {
        final icon = response['icon'] as String?;
        final projectTitle = response['title'] as String? ?? (followUpAnswer != null ? 'Project' : prompt);
        final subtasks = response['subtasks'] as List<dynamic>? ?? [];
        
        if (!mounted) return;
        context.read<ProductivityBloc>().add(
          ProductivityEvent.createProjectWithSubtasks(projectTitle, icon, subtasks)
        );
        _aiProjectController.clear();
      } else {
        if (!mounted) return;
        context.read<ProductivityBloc>().add(ProductivityEvent.createProjectWithSubtasks(prompt, null, response as List<dynamic>));
        _aiProjectController.clear();
      }
    } catch (e) {
      debugPrint("Generation error: $e");
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showClarificationDialog(String question) {
    final answerController = TextEditingController();
    final originalPrompt = _aiProjectController.text.trim();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.accentViolet.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentViolet.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.accentViolet, size: 40),
              const SizedBox(height: 16),
              Text(
                question,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: answerController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Your answer...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                onSubmitted: (val) {
                  Navigator.of(ctx).pop();
                  final answer = answerController.text.trim();
                  if (answer.isNotEmpty) {
                    _generateProject('Goal: $originalPrompt. Detail: $answer');
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      final answer = answerController.text.trim();
                      if (answer.isNotEmpty) {
                        _generateProject('Goal: $originalPrompt. Detail: $answer');
                      }
                    },
                    child: const Text('Continue'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectDetails(BuildContext context, Task project, List<Task> subtasks) {
    final bloc = context.read<ProductivityBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<ProductivityBloc, ProductivityState>(
          builder: (context, state) {
            List<Task> currentSubtasks = subtasks;
            List<Note> currentRelatedNotes = [];
            state.maybeWhen(
              loaded: (allTasks, _, allNotes) {
                currentSubtasks = allTasks.where((t) => t.parentId == project.id).toList();
                currentRelatedNotes = allNotes.where((note) => note.linkedTaskIds.contains(project.id)).toList();
              },
              orElse: () {},
            );

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ]
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          project.icon ?? '🚀',
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            project.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                  if (currentRelatedNotes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Text('Related Notes (AI Auto-Linked)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
                          ),
                          ...currentRelatedNotes.map((note) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: AppTheme.accentCyan, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.auto_awesome, color: AppTheme.accentCyan, size: 20),
                              title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              dense: true,
                            ),
                          )),
                          const Divider(height: 24),
                        ],
                      ),
                    ),
                  Expanded(
                    child: currentSubtasks.isEmpty
                      ? const Center(child: Text("No tasks in this project yet.", style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: currentSubtasks.length,
                          itemBuilder: (context, index) {
                            final task = currentSubtasks[index];
                            return _TaskListItem(key: ValueKey(task.id), task: task);
                          },
                        ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
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
              onSubmitted: (val) => _generateProject(),
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
                    _showProjectDetails(context, project, subtasks);
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentViolet.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                project.icon ?? '🚀',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
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
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
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

class _TaskListItem extends StatefulWidget {
  final Task task;

  const _TaskListItem({super.key, required this.task});

  @override
  State<_TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<_TaskListItem> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveTitle();
      }
    });
  }

  void _saveTitle() {
    if (_isEditing) {
      final newTitle = _controller.text.trim();
      if (newTitle.isNotEmpty && newTitle != widget.task.title) {
        widget.task.title = newTitle;
        widget.task.updatedAt = DateTime.now();
        context.read<ProductivityBloc>().add(ProductivityEvent.updateTask(widget.task));
      } else {
        _controller.text = widget.task.title;
      }
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentViolet.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: widget.task.isCompleted,
          activeColor: AppTheme.accentMint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (val) {
            if (val == true && !widget.task.isCompleted) {
              context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(widget.task.id));
            }
          },
        ),
        title: _isEditing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _saveTitle(),
              )
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                child: Text(
                  widget.task.title, 
                  style: TextStyle(
                    fontSize: 16,
                    decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                    color: widget.task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                  )
                ),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary, size: 20),
          onPressed: () => context.read<ProductivityBloc>().add(ProductivityEvent.deleteTask(widget.task.id)),
        ),
      ),
    );
  }
}
