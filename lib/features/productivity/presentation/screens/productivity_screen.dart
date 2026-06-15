import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/productivity_bloc.dart';
import '../bloc/calendar_bloc.dart';
import '../widgets/daily_checklist.dart';
import '../widgets/project_cards_view.dart';
import '../widgets/notes_masonry_grid.dart';
import '../widgets/calendar_tab_view.dart';
import '../../data/models/productivity_collections.dart';

import 'package:flutter/services.dart';

import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/core/di/injection.dart';
import 'package:kero_space/shared/widgets/shimmer/productivity_skeleton.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';
import '../widgets/deep_work_timer_widget.dart';

class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});

  @override
  State<ProductivityScreen> createState() => _ProductivityScreenState();
}

class _ProductivityScreenState extends State<ProductivityScreen> with SingleTickerProviderStateMixin {
  static const _methodsChannel = MethodChannel('kero_space/methods');
  int _selectedEnergyLevel = 2; // Default to Medium

  void _startDeepWork() async {
    try {
      await _methodsChannel.invokeMethod('startDeepWork', {'durationMinutes': 25});
    } catch (e) {
      debugPrint("Failed to start deep work: $e");
    }
  }

  void _updateTaskGatedMode(bool hasPendingHighPriorityTask) async {
    try {
      await _methodsChannel.invokeMethod('setPendingHighPriorityTask', {'hasTask': hasPendingHighPriorityTask});
    } catch (e) {
      debugPrint("Failed to set task gated mode: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ProductivityBloc>()..add(const ProductivityEvent.loadData())),
        BlocProvider.value(value: getIt<CalendarBloc>()..add(const CalendarEventBlocEvent.loadEvents())),
      ],
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Productivity'),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Today"),
                Tab(text: "Projects"),
                Tab(text: "Notes"),
                Tab(text: "Calendar"),
              ],
            ),
          ),
          body: BlocBuilder<ProductivityBloc, ProductivityState>(
            builder: (context, state) {
              return state.when(
                loading: () => const ProductivitySkeleton(),
                error: (msg) => InlineErrorWidget(
                  message: msg,
                  onRetry: () => context.read<ProductivityBloc>().add(const ProductivityEvent.loadData()),
                ),
                loaded: (allTasks, dailyChecklist, allNotes) {
                  // Check if there are any high priority tasks pending for enforcement
                  final hasHighPriorityPending = dailyChecklist.any((t) => !t.isCompleted && (t.energyLevel == 3));
                  _updateTaskGatedMode(hasHighPriorityPending);

                  return TabBarView(
                    children: [
                      // Tab 1: Today
                      CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: DeepWorkTimerWidget(onStartDeepWork: _startDeepWork),
                          ),
                          
                          // Fasting Badge
                          SliverToBoxAdapter(
                            child: BlocBuilder<CalendarBloc, CalendarState>(
                              builder: (context, calState) {
                                return calState.maybeWhen(
                                  loaded: (events) {
                                    final today = DateTime.now();
                                    final fastEvent = events.firstWhere(
                                      (e) => e.source == 'COPTIC' && e.startTime.year == today.year && e.startTime.month == today.month && e.startTime.day == today.day,
                                      orElse: () => CalendarEvent()..source = 'NONE',
                                    );
                                    if (fastEvent.source == 'COPTIC') {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentViolet.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(16.0),
                                          border: Border.all(color: AppTheme.accentViolet.withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.restaurant_menu, color: AppTheme.accentViolet),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "Today is a Fasting Day: ${fastEvent.title}. Strictly Vegan.",
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentViolet),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  orElse: () => const SizedBox.shrink(),
                                );
                              },
                            ),
                          ),

                          // Energy Filters & Checklist isolated
                          SliverToBoxAdapter(
                            child: StatefulBuilder(
                              builder: (context, setEnergyState) {
                                final filteredChecklist = dailyChecklist.where((t) => (t.energyLevel ?? 2) == _selectedEnergyLevel).toList();
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: SegmentedButton<int>(
                                        segments: const [
                                          ButtonSegment(value: 1, label: Text('Low Energy'), icon: Icon(Icons.battery_2_bar)),
                                          ButtonSegment(value: 2, label: Text('Medium Energy'), icon: Icon(Icons.battery_5_bar)),
                                          ButtonSegment(value: 3, label: Text('High Focus'), icon: Icon(Icons.battery_full)),
                                        ],
                                        selected: {_selectedEnergyLevel},
                                        onSelectionChanged: (Set<int> newSelection) {
                                          setEnergyState(() {
                                            _selectedEnergyLevel = newSelection.first;
                                          });
                                        },
                                      ),
                                    ),
                                    if (filteredChecklist.isEmpty)
                                      const Padding(padding: EdgeInsets.all(32.0), child: Text("No tasks for this energy level today."))
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredChecklist.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                            child: TaskRow(task: filteredChecklist[index]),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              }
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 100)),
                        ],
                      ),
                      
                      // Tab 2: Projects Hub
                      ProjectCardsView(allTasks: allTasks),

                      // Tab 3: Notes
                      NotesMasonryGrid(notes: allNotes),

                      // Tab 4: Calendar
                      CalendarTabView(allTasks: allTasks),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: Builder(
            builder: (fabContext) => FloatingActionButton.extended(
              onPressed: () {
                final tabController = DefaultTabController.of(fabContext);
                final bloc = fabContext.read<ProductivityBloc>();
                if (tabController.index == 2) {
                  // Notes tab
                  fabContext.push('/note_editor', extra: {'bloc': bloc});
                } else {
                  // Projects / Today tab
                  _showCreateTaskBottomSheet(fabContext, bloc);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTaskBottomSheet(BuildContext context, ProductivityBloc bloc) {
    TaskType selectedType = TaskType.task;
    int energyLevel = 2;
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create New', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SegmentedButton<TaskType>(
                    segments: const [
                      ButtonSegment(value: TaskType.task, label: Text('Task')),
                      ButtonSegment(value: TaskType.project, label: Text('Project')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      setModalState(() => selectedType = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: selectedType == TaskType.task ? 'What needs to be done?' : 'Project goal...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                  ),
                  if (selectedType == TaskType.task) ...[
                    const SizedBox(height: 16),
                    const Text('Energy Required:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('Low')),
                        ButtonSegment(value: 2, label: Text('Medium')),
                        ButtonSegment(value: 3, label: Text('High')),
                      ],
                      selected: {energyLevel},
                      onSelectionChanged: (selection) {
                        setModalState(() => energyLevel = selection.first);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.accentViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        final newTask = Task()
                          ..title = titleController.text.trim()
                          ..type = selectedType
                          ..energyLevel = selectedType == TaskType.task ? energyLevel : null
                          ..deviceId = 'local'
                          ..platform = 'local'
                          ..createdAt = DateTime.now();
                        bloc.add(ProductivityEvent.createTask(newTask));
                      }
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Create', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
