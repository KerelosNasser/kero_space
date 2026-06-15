import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../bloc/calendar_bloc.dart';
import '../bloc/productivity_bloc.dart';
import '../../data/models/productivity_collections.dart';
import '../../../../../core/app_theme.dart';

class CalendarTabView extends StatefulWidget {
  final List<Task> allTasks;

  const CalendarTabView({super.key, required this.allTasks});

  @override
  State<CalendarTabView> createState() => _CalendarTabViewState();
}

class _CalendarTabViewState extends State<CalendarTabView> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, calState) {
        return calState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (msg) => Center(child: Text("Error: $msg")),
          loaded: (events) {
            final dayEvents = events.where((e) => 
                e.startTime.year == _selectedDay.year && 
                e.startTime.month == _selectedDay.month && 
                e.startTime.day == _selectedDay.day
            ).toList();

            final dayTasks = widget.allTasks.where((t) => 
                !t.isCompleted && t.dueDate != null &&
                t.dueDate!.year == _selectedDay.year && 
                t.dueDate!.month == _selectedDay.month && 
                t.dueDate!.day == _selectedDay.day
            ).toList();

            final agendaItems = [...dayEvents, ...dayTasks];
            agendaItems.sort((a, b) {
              final aTime = a is CalendarEvent ? a.startTime : (a as Task).dueDate!;
              final bTime = b is CalendarEvent ? b.startTime : (b as Task).dueDate!;
              return aTime.compareTo(bTime);
            });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<ProductivityBloc>().add(const ProductivityEvent.autoScheduleTasks());
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Auto-Fill Empty Slots'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentViolet,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _selectedDay,
                  currentDay: _selectedDay,
                  calendarFormat: CalendarFormat.week,
                  availableCalendarFormats: const {
                    CalendarFormat.week: 'Week',
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.accentCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                  },
                  eventLoader: (day) {
                    return events.where((e) => 
                      e.startTime.year == day.year && 
                      e.startTime.month == day.month && 
                      e.startTime.day == day.day
                    ).toList();
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, eventList) {
                      if (eventList.isEmpty) return const SizedBox();
                      
                      final hasCoptic = eventList.any((e) => (e as CalendarEvent).source == 'COPTIC');
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                              color: hasCoptic ? AppTheme.accentViolet : AppTheme.accentCyan,
                          ),
                          width: 7.0,
                          height: 7.0,
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: agendaItems.isEmpty 
                    ? const Center(child: Text("Free time. Be lazy."))
                    : ListView.builder(
                    itemCount: agendaItems.length,
                    itemBuilder: (context, index) {
                      final item = agendaItems[index];
                      if (item is CalendarEvent) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Container(
                              width: 4,
                              color: item.source == 'COPTIC' ? AppTheme.accentViolet : AppTheme.accentCyan,
                            ),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')} - ${item.source}"),
                          ),
                        );
                      } else if (item is Task) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: AppTheme.accentCyan, width: 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline, color: AppTheme.accentCyan),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Scheduled Task • ${item.dueDate!.hour.toString().padLeft(2, '0')}:${item.dueDate!.minute.toString().padLeft(2, '0')}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.check, color: AppTheme.accentMint),
                              onPressed: () {
                                context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(item.id));
                              },
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
