import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/habits/data/models/habit_model.dart';

void main() {
  group('Habit Streak Calculation Tests', () {
    test('calculateStreak returns 0 for empty completed dates', () {
      final streak = Habit.calculateStreak({}, DateTime(2026, 9, 19));
      expect(streak, 0);
    });

    test('calculateStreak counts consecutive past days including today', () {
      final dates = {
        '2026-09-17',
        '2026-09-18',
        '2026-09-19',
      };
      final streak = Habit.calculateStreak(dates, DateTime(2026, 9, 19));
      expect(streak, 3);
    });

    test('calculateStreak preserves active streak if completed yesterday but not yet today', () {
      final dates = {
        '2026-09-16',
        '2026-09-17',
        '2026-09-18', // yesterday
      };
      // Today is Sept 19, not yet completed
      final streak = Habit.calculateStreak(dates, DateTime(2026, 9, 19));
      expect(streak, 3);
    });

    test('calculateStreak resets if missed both today and yesterday', () {
      final dates = {
        '2026-09-15',
        '2026-09-16',
        '2026-09-17',
        // Missed Sept 18 (yesterday) and Sept 19 (today)
      };
      final streak = Habit.calculateStreak(dates, DateTime(2026, 9, 19));
      expect(streak, 0);
    });

    test('Habit serialization roundtrip works correctly', () {
      const habit = Habit(
        id: 'test-01',
        title: 'Morning Water',
        description: 'Drink 500ml',
        category: HabitCategory.health,
        streakCount: 5,
        bestStreak: 10,
        completedDates: {'2026-09-18', '2026-09-19'},
        colorValue: 0xFF42A5F5,
        iconCode: 'water_drop',
      );

      final json = habit.toJson();
      final restored = Habit.fromJson(json);

      expect(restored.id, habit.id);
      expect(restored.title, habit.title);
      expect(restored.category, HabitCategory.health);
      expect(restored.streakCount, 5);
      expect(restored.bestStreak, 10);
      expect(restored.completedDates.length, 2);
    });
  });
}
