import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:table_calendar/table_calendar.dart';

import '../bloc/productivity_bloc.dart';
import '../bloc/calendar_bloc.dart';
import '../widgets/daily_checklist.dart';
import '../widgets/project_cards_view.dart';
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

class _ProductivityScreenState extends State<ProductivityScreen> {
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
                  // Filter checklist by energy level
                  final filteredChecklist = dailyChecklist.where((t) => (t.energyLevel ?? 2) == _selectedEnergyLevel).toList();
                  
                  // Check if there are any high priority tasks pending for enforcement
                  final hasHighPriorityPending = dailyChecklist.any((t) => !t.isCompleted && (t.energyLevel == 3));
                  _updateTaskGatedMode(hasHighPriorityPending);

                  return CustomScrollView(
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

                      // Energy Filters
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 1, label: Text('Low Energy'), icon: Icon(Icons.battery_2_bar)),
                              ButtonSegment(value: 2, label: Text('Medium Energy'), icon: Icon(Icons.battery_5_bar)),
                              ButtonSegment(value: 3, label: Text('High Focus'), icon: Icon(Icons.battery_full)),
                            ],
                            selected: {_selectedEnergyLevel},
                            onSelectionChanged: (Set<int> newSelection) {
                              setState(() {
                                _selectedEnergyLevel = newSelection.first;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // Filtered Checklist
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        sliver: filteredChecklist.isEmpty 
                          ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No tasks for this energy level today."))))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: TaskRow(task: filteredChecklist[index]),
                                  );
                                },
                                childCount: filteredChecklist.length,
                              ),
                            ),
                      ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text("Projects Hub", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 350,
                          child: ProjectCardsView(allTasks: allTasks),
                        ),
                      ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for FAB
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateTaskDialog(context, context.read<ProductivityBloc>()),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        ),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, ProductivityBloc bloc) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project / Task'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Enter title...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final newTask = Task()
                  ..title = titleController.text
                  ..type = TaskType.project
                  ..deviceId = 'local'
                  ..platform = 'local'
                  ..createdAt = DateTime.now();
                bloc.add(ProductivityEvent.createTask(newTask));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
