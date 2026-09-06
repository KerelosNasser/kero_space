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
          ProductivityEvent.createProjectWithSubtasks(projectTitle, icon, subtasks),
        );
        _aiProjectController.clear();
      } else {
        if (!mounted) return;
        context.read<ProductivityBloc>().add(
          ProductivityEvent.createProjectWithSubtasks(prompt, null, response as List<dynamic>),
        );
        _aiProjectController.clear();
      }
    } catch (e) {
      debugPrint("Generation error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate project: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showClarificationDialog(String question) {
    final answerController = TextEditingController();
    final originalPrompt = _aiProjectController.text.trim();
    final colors = context.appColors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.domainProductivity.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: colors.domainProductivity.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: colors.domainProductivity, size: 40),
              const SizedBox(height: 16),
              Text(
                question,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
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
                  fillColor: colors.bgElevated,
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
                    child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.domainProductivity,
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

  void _confirmDeleteProject(BuildContext context, Task project) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurface,
        title: Text(
          'Delete Project?',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${project.title}" and all its subtasks?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentError,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<ProductivityBloc>().add(ProductivityEvent.deleteTask(project.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(BuildContext context, Task project, List<Task> subtasks) {
    final bloc = context.read<ProductivityBloc>();
    final colors = context.appColors;

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
                color: colors.bgSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
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
                        color: colors.textDisabled.withValues(alpha: 0.3),
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
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colors.textSecondary),
                          onPressed: () => Navigator.of(ctx).pop(),
                        )
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.borderSubtle),
                  if (currentRelatedNotes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Text(
                              'Related Notes (AI Auto-Linked)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: colors.domainProductivity),
                            ),
                          ),
                          ...currentRelatedNotes.map((note) => Card(
                            color: colors.bgElevated,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: colors.domainProductivity, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.auto_awesome, color: colors.domainProductivity, size: 20),
                              title: Text(note.title, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                              dense: true,
                            ),
                          )),
                          Divider(height: 24, color: colors.borderSubtle),
                        ],
                      ),
                    ),
                  Expanded(
                    child: currentSubtasks.isEmpty
                        ? Center(
                            child: Text(
                              "No tasks in this project yet.",
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          )
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
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final projects = widget.allTasks.where((t) => t.type == TaskType.project).toList();

    return Column(
      children: [
        // AI Lazy Creation Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: TextField(
              controller: _aiProjectController,
              decoration: InputDecoration(
                hintText: 'Lazy? Type "Plan Vacation" and AI will build it.',
                prefixIcon: Icon(Icons.auto_awesome, color: colors.domainProductivity),
                suffixIcon: _isGenerating
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.send, color: colors.domainProductivity),
                        onPressed: () => _generateProject(),
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
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 64,
                      color: colors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No projects yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type a goal in the AI prompt above or tap Add to create your first project.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
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
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.borderSubtle),
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.domainProductivity.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                project.icon ?? '🚀',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: colors.textSecondary),
                              onPressed: () => _confirmDeleteProject(context, project),
                              tooltip: 'Delete Project',
                            )
                          ],
                        ),
                        const Spacer(),
                        Text(
                          project.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                            color: colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${subtasks.length} tasks",
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: colors.bgSurface,
                          color: colors.accentSuccess,
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
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: widget.task.isCompleted,
          activeColor: colors.accentSuccess,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (val) {
            if (val == true && !widget.task.isCompleted) {
              context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(widget.task.id));
            } else if (val == false && widget.task.isCompleted) {
              context.read<ProductivityBloc>().add(ProductivityEvent.uncompleteTask(widget.task.id));
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
                    color: widget.task.isCompleted ? colors.textDisabled : colors.textPrimary,
                  ),
                ),
              ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colors.textSecondary, size: 20),
          onPressed: () => context.read<ProductivityBloc>().add(ProductivityEvent.deleteTask(widget.task.id)),
        ),
      ),
    );
  }
}
