import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/features/habits/data/models/habit_model.dart';
import 'package:kero_space/features/habits/data/repositories/habit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getHabits seeds default Phone Detox starter pack on first run', () async {
      final repo = HabitRepository();
      final habits = await repo.getHabits();

      expect(habits.isNotEmpty, true);
      expect(habits.length, HabitRepository.defaultStarterPack.length);
      expect(habits.any((h) => h.title.contains('Morning Phone-Free')), true);
    });

    test('toggleHabitToday marks habit completed and increments streak', () async {
      final repo = HabitRepository();
      final habits = await repo.getHabits();
      final target = habits.first;

      expect(target.isCompletedToday, false);
      expect(target.streakCount, 0);

      final updated = await repo.toggleHabitToday(target.id);
      expect(updated, isNotNull);
      expect(updated!.isCompletedToday, true);
      expect(updated.streakCount, 1);

      // Untoggle
      final untoggled = await repo.toggleHabitToday(target.id);
      expect(untoggled!.isCompletedToday, false);
      expect(untoggled.streakCount, 0);
    });

    test('addHabit and deleteHabit update persistent list', () async {
      final repo = HabitRepository();
      const newHabit = Habit(
        id: 'custom-01',
        title: 'Learn Flutter 30m',
        category: HabitCategory.focus,
      );

      await repo.addHabit(newHabit);
      var habits = await repo.getHabits();
      expect(habits.any((h) => h.id == 'custom-01'), true);

      await repo.deleteHabit('custom-01');
      habits = await repo.getHabits();
      expect(habits.any((h) => h.id == 'custom-01'), false);
    });
  });
}
