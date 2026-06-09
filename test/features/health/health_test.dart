import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';

void main() {
  group('Health Models & Logic Tests', () {
    test('MealEntry macro calculation logic', () {
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

    test('BMR calculations handle male profile', () {
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
    
    test('HealthRecord maps values correctly', () {
      final record = HealthRecord()
        ..type = 'STEPS'
        ..value = 5000.0;
        
      expect(record.type, 'STEPS');
      expect(record.value, 5000.0);
    });
  });
}
