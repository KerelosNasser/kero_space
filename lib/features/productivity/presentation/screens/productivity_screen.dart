import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:table_calendar/table_calendar.dart';

import '../bloc/productivity_bloc.dart';
import '../bloc/calendar_bloc.dart';
import '../widgets/daily_checklist.dart';
import '../widgets/task_tree_view.dart';
import '../../data/models/productivity_collections.dart';

import 'package:kero_space/core/di/injection.dart';

class ProductivityScreen extends StatelessWidget {
  const ProductivityScreen({super.key});

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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (msg) => Center(child: Text("Error: \$msg")),
                loaded: (allTasks, dailyChecklist, allNotes) {
                  return TabBarView(
                    children: [
                      // Tab 1: Today's Checklist & Fasting Badge
                      Column(
                        children: [
                          BlocBuilder<CalendarBloc, CalendarState>(
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
                                      margin: const EdgeInsets.all(8.0),
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: Border.all(color: Colors.purple),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.restaurant_menu, color: Colors.purple),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Today is a Fasting Day: ${fastEvent.title}. Strictly Vegan (No meat/dairy).",
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
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
                          Expanded(child: DailyChecklist(tasks: dailyChecklist)),
                        ],
                      ),
                      
                      // Tab 2: Projects Tree View
                      TaskTreeView(allTasks: allTasks),
                      
                      // Tab 3: Notes
                      ListView.builder(
                        itemCount: allNotes.length,
                        itemBuilder: (context, index) {
                          final note = allNotes[index];
                          return ListTile(
                            title: Text(note.title),
                            onTap: () => context.push('/note_editor', extra: {'note': note, 'bloc': context.read<ProductivityBloc>()}),
                          );
                        },
                      ),
                      // Tab 4: Calendar
                      BlocBuilder<CalendarBloc, CalendarState>(
                        builder: (context, calState) {
                          return calState.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (msg) => Center(child: Text("Error: $msg")),
                            loaded: (events) {
                              return Column(
                                children: [
                                  TableCalendar(
                                    firstDay: DateTime.utc(2020, 10, 16),
                                    lastDay: DateTime.utc(2030, 3, 14),
                                    focusedDay: DateTime.now(),
                                    eventLoader: (day) {
                                      return events.where((e) => 
                                        e.startTime.year == day.year && 
                                        e.startTime.month == day.month && 
                                        e.startTime.day == day.day
                                      ).toList();
                                    },
                                    calendarFormat: CalendarFormat.month,
                                    calendarBuilders: CalendarBuilders(
                                      markerBuilder: (context, date, eventList) {
                                        if (eventList.isEmpty) return const SizedBox();
                                        
                                        final hasCoptic = eventList.any((e) => (e as CalendarEvent).source == 'COPTIC');
                                        return Positioned(
                                          bottom: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: hasCoptic ? Colors.purple : Colors.blue,
                                            ),
                                            width: 7.0,
                                            height: 7.0,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: events.length,
                                      itemBuilder: (context, index) {
                                        final event = events[index];
                                        return ListTile(
                                          title: Text(event.title),
                                          subtitle: Text("${event.startTime.toLocal()} - ${event.source}"),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: Builder(
            builder: (fabContext) => FloatingActionButton(
              onPressed: () {
                final tabController = DefaultTabController.of(fabContext);
                final bloc = fabContext.read<ProductivityBloc>();
                if (tabController.index == 2) {
                  // Notes tab
                  fabContext.push('/note_editor', extra: {'bloc': bloc});
                } else {
                  // Projects / Today tab
                  _showCreateTaskDialog(fabContext, bloc);
                }
              },
              child: const Icon(Icons.add),
            ),
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
