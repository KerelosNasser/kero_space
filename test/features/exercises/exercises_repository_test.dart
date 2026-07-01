import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/exercises/data/repositories/exercises_repository.dart';

void main() {
  group('ExercisesRepository seed mapping', () {
    test('maps exercise seed fields from the asset shape', () {
      final exercise = ExercisesRepository.mapExerciseFromSeed({
        'id': '0001',
        'name': '3/4 sit-up',
        'category': 'waist',
        'body_part': 'waist',
        'equipment': 'body weight',
        'instructions': {'en': 'Sit up with control.'},
        'secondary_muscles': ['hip flexors'],
      });

      expect(exercise.id, '0001');
      expect(exercise.name, '3/4 sit-up');
      expect(exercise.category, 'waist');
      expect(exercise.target, 'waist');
      expect(exercise.equipment, 'body weight');
      expect(exercise.instructionsEn, 'Sit up with control.');
      expect(exercise.secondaryMuscles, ['hip flexors']);
    });

    test(
      'falls back to instruction steps when english instructions are absent',
      () {
        final instructions = ExercisesRepository.extractEnglishInstructions(
          const {},
          {
            'en': ['Brace your core.', 'Lower with control.'],
          },
        );

        expect(instructions, 'Brace your core. Lower with control.');
      },
    );
  });

  group('ExercisesRepository schedule resolution', () {
    test('uses explicit weekday masks when present', () {
      const split = WorkoutSplitDefinition(
        id: 'upper-lower',
        name: 'Upper/Lower',
        description: 'desc',
        daysPerWeek: 4,
        days: [
          WorkoutDayDefinition(
            name: 'Upper A',
            sortOrder: 1,
            dayOfWeekMask: 1,
            focuses: ['chest'],
          ),
          WorkoutDayDefinition(
            name: 'Lower A',
            sortOrder: 2,
            dayOfWeekMask: 2,
            focuses: ['upper legs'],
          ),
        ],
      );

      final monday = ExercisesRepository.resolveDayForDate(
        split,
        DateTime(2026, 7, 6),
      );
      final tuesday = ExercisesRepository.resolveDayForDate(
        split,
        DateTime(2026, 7, 7),
      );

      expect(monday.name, 'Upper A');
      expect(tuesday.name, 'Lower A');
    });

    test('falls back to rotation when weekday mask is missing', () {
      const split = WorkoutSplitDefinition(
        id: 'fallback',
        name: 'Fallback',
        description: 'desc',
        daysPerWeek: 3,
        days: [
          WorkoutDayDefinition(
            name: 'Day 1',
            sortOrder: 1,
            dayOfWeekMask: 0,
            focuses: ['chest'],
          ),
          WorkoutDayDefinition(
            name: 'Day 2',
            sortOrder: 2,
            dayOfWeekMask: 0,
            focuses: ['back'],
          ),
          WorkoutDayDefinition(
            name: 'Day 3',
            sortOrder: 3,
            dayOfWeekMask: 0,
            focuses: ['legs'],
          ),
        ],
      );

      final saturday = ExercisesRepository.resolveDayForDate(
        split,
        DateTime(2026, 7, 4),
      );

      expect(saturday.name, 'Day 3');
    });
  });
}
