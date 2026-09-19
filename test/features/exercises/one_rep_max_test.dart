import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/exercises/presentation/screens/exercise_detail_screen.dart';

void main() {
  group('1RM Calculation Tests', () {
    test('calculate1RM returns weight for 1 rep', () {
      expect(ExerciseDetailScreen.calculate1RM(100.0, 1), 100.0);
    });

    test('calculate1RM returns 0.0 for non-positive inputs', () {
      expect(ExerciseDetailScreen.calculate1RM(0.0, 10), 0.0);
      expect(ExerciseDetailScreen.calculate1RM(100.0, 0), 0.0);
      expect(ExerciseDetailScreen.calculate1RM(-50.0, 5), 0.0);
    });

    test('calculate1RM uses Epley formula correctly', () {
      // 100 kg x 10 reps -> 100 * (1 + 10/30) = 100 * 1.3333... ~ 133.33 kg
      final est1RM = ExerciseDetailScreen.calculate1RM(100.0, 10);
      expect(est1RM, closeTo(133.33, 0.01));
    });

    test('calculate1RM calculates correct 1RM for typical bench press set', () {
      // 80 kg x 8 reps -> 80 * (1 + 8/30) = 80 * 1.2666... ~ 101.33 kg
      final est1RM = ExerciseDetailScreen.calculate1RM(80.0, 8);
      expect(est1RM, closeTo(101.33, 0.01));
    });
  });
}
