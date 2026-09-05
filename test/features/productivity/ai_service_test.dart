import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/productivity/data/services/ai_service.dart';

void main() {
  group('AIService.autoScheduleTasks', () {
    final aiService = AIService();

    test('schedules empty task list to empty map', () async {
      final schedule = await aiService.autoScheduleTasks([]);
      expect(schedule, isEmpty);
    });

    test('schedules tasks within working hours (09:00 - 18:00)', () async {
      final tasks = [
        {'id': 1, 'title': 'Task A', 'energyLevel': 3},
        {'id': 2, 'title': 'Task B', 'energyLevel': 1},
      ];

      final base = DateTime(2026, 9, 10, 8, 0); // 8 AM
      final schedule = await aiService.autoScheduleTasks(
        tasks,
        referenceDate: base,
      );

      expect(schedule.length, 2);
      for (final time in schedule.values) {
        expect(time.hour >= 9, isTrue, reason: 'Hour should be >= 9');
        expect(time.hour < 18, isTrue, reason: 'Hour should be < 18');
      }
    });

    test('avoids busy slots when scheduling', () async {
      final base = DateTime(2026, 9, 10, 9, 0);
      // Busy slot from 09:00 to 10:30
      final busy = [
        DateTimeRange(
          start: DateTime(2026, 9, 10, 9, 0),
          end: DateTime(2026, 9, 10, 10, 30),
        ),
      ];

      final tasks = [
        {'id': 10, 'title': 'Deep Work', 'energyLevel': 3},
      ];

      final schedule = await aiService.autoScheduleTasks(
        tasks,
        referenceDate: base,
        customBusySlots: busy,
      );

      final scheduledTime = schedule[10]!;
      expect(
        scheduledTime.isAfter(DateTime(2026, 9, 10, 10, 29)),
        isTrue,
        reason: 'Should be scheduled after the busy slot',
      );
    });

    test('prioritizes high energy tasks before low energy tasks', () async {
      final base = DateTime(2026, 9, 10, 9, 0);
      final tasks = [
        {'id': 1, 'title': 'Low Energy Task', 'energyLevel': 1},
        {'id': 2, 'title': 'High Focus Deep Work', 'energyLevel': 3},
      ];

      final schedule = await aiService.autoScheduleTasks(
        tasks,
        referenceDate: base,
      );

      final highEnergyTime = schedule[2]!;
      final lowEnergyTime = schedule[1]!;

      expect(
        highEnergyTime.isBefore(lowEnergyTime),
        isTrue,
        reason: 'High energy task should be scheduled before low energy task',
      );
    });
  });
}
