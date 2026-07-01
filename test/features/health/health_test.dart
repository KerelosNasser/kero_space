import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/data/repositories/nutrition_repository.dart';

void main() {
  group('NutritionRepository ingredient seed mapping', () {
    test('fills missing optional nutrition fields with zero defaults', () {
      final ingredient = NutritionRepository.ingredientFromSeedMap({
        'name': 'Ful Medames',
        'calories': 110,
        'protein': 7.6,
        'carbs': 19.7,
        'fat': 0.4,
        'isFastingCompliant': true,
      });

      expect(ingredient.name, 'Ful Medames');
      expect(ingredient.calories, 110);
      expect(ingredient.protein, 7.6);
      expect(ingredient.carbs, 19.7);
      expect(ingredient.fat, 0.4);
      expect(ingredient.fiber, 0.0);
      expect(ingredient.sugar, 0.0);
      expect(ingredient.fastCarbs, 0.0);
      expect(ingredient.slowCarbs, 0.0);
      expect(ingredient.fatSaturated, 0.0);
      expect(ingredient.fatUnsaturated, 0.0);
      expect(ingredient.cholesterol, 0.0);
      expect(ingredient.sodium, 0.0);
      expect(ingredient.glycemicIndex, 0.0);
      expect(ingredient.isFastingCompliant, isTrue);
    });

    test('normalizes blank names and absent fasting flag safely', () {
      final ingredient = NutritionRepository.ingredientFromSeedMap({
        'name': '   ',
        'calories': 42,
      });

      expect(ingredient.name, 'Unknown ingredient');
      expect(ingredient.calories, 42.0);
      expect(ingredient.isFastingCompliant, isFalse);
    });
  });

  group('Health data models', () {
    test('meal entry stores macro values', () {
      final entry = MealEntry()
        ..name = 'Koshary'
        ..calories = 500
        ..protein = 15
        ..carbs = 80
        ..fat = 10;

      expect(entry.calories, 500);
      expect(entry.protein, 15);
      expect(entry.carbs, 80);
      expect(entry.fat, 10);
    });

    test('user profile stores BMR-related values', () {
      final profile = UserProfile()
        ..deviceId = 'test-device'
        ..platform = 'test-platform'
        ..height = 180.0
        ..weight = 75.0
        ..age = 25
        ..activityLevel = 1.2
        ..bmrTarget = 2000.0
        ..timestamp = DateTime.now();

      expect(profile.height, 180.0);
      expect(profile.bmrTarget, greaterThan(1500));
      expect(profile.bmrTarget, lessThan(4000));
    });

    test('health record stores telemetry values on value', () {
      final record = HealthRecord()
        ..type = 'STEPS'
        ..value = 5000.0;

      expect(record.type, 'STEPS');
      expect(record.value, 5000.0);
    });
  });
}
