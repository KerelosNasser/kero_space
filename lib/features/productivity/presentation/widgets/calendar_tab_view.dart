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
    final colors = context.appColors;

    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, calState) {
        return calState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (msg) => Center(child: Text("Error: $msg", style: TextStyle(color: colors.accentError))),
          loaded: (events) {
            final dayEvents = events.where((e) =>
                e.startTime.year == _selectedDay.year &&
                e.startTime.month == _selectedDay.month &&
                e.startTime.day == _selectedDay.day
            ).toList();

            final dayTasks = widget.allTasks.where((t) =>
                t.dueDate != null &&
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<ProductivityBloc>().add(const ProductivityEvent.autoScheduleTasks());
                      },
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: const Text('Auto-Fill Empty Slots', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.domainProductivity,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _selectedDay,
                  currentDay: DateTime.now(),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.week,
                  availableCalendarFormats: const {
                    CalendarFormat.week: 'Week',
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: colors.textPrimary),
                    rightChevronIcon: Icon(Icons.chevron_right, color: colors.textPrimary),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(color: colors.textPrimary),
                    weekendTextStyle: TextStyle(color: colors.textSecondary),
                    todayDecoration: BoxDecoration(
                      color: colors.domainProductivity.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(
                      color: colors.domainProductivity,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        bottom: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasCoptic ? colors.domainChurch : colors.domainProductivity,
                          ),
                          width: 6.0,
                          height: 6.0,
                        ),
                      );
                    },
                  ),
                ),
                Divider(color: colors.borderSubtle),
                Expanded(
                  child: agendaItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available_outlined, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                "No events or tasks scheduled",
                                style: TextStyle(color: colors.textSecondary, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: agendaItems.length,
                          itemBuilder: (context, index) {
                            final item = agendaItems[index];
                            if (item is CalendarEvent) {
                              final isCoptic = item.source == 'COPTIC';
                              return Card(
                                color: colors.bgElevated,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: colors.borderSubtle),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 4,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isCoptic ? colors.domainChurch : colors.domainProductivity,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                  subtitle: Text(
                                    "${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')} • ${item.source}",
                                    style: TextStyle(color: colors.textSecondary),
                                  ),
                                ),
                              );
                            } else if (item is Task) {
                              return Card(
                                color: colors.bgElevated,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: item.isCompleted ? colors.borderSubtle : colors.domainProductivity.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: item.isCompleted,
                                    activeColor: colors.accentSuccess,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    onChanged: (val) {
                                      if (val == true) {
                                        context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(item.id));
                                      } else {
                                        context.read<ProductivityBloc>().add(ProductivityEvent.uncompleteTask(item.id));
                                      }
                                    },
                                  ),
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.isCompleted ? colors.textDisabled : colors.textPrimary,
                                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Scheduled Task • ${item.dueDate!.hour.toString().padLeft(2, '0')}:${item.dueDate!.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: colors.textSecondary),
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
