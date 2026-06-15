import 'package:isar/isar.dart';

part 'health_collections.g.dart';

@collection
class HealthRecord {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String type; // 'STEPS', 'HEART_RATE', 'SLEEP'
  late double value;
  late DateTime timestamp;
}

enum MealType { breakfast, lunch, dinner, snack }

@collection
class MealEntry {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String name;
  late double grams;
  late double calories;
  late double protein;
  late double carbs;
  late double fat;
  late DateTime timestamp;
  @enumerated
  MealType mealType = MealType.snack;
}

@collection
class Ingredient {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String name;
  late double calories;
  late double protein;
  late double carbs;
  late double fat;
  late bool isFastingCompliant;
}

@collection
class UserProfile {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late double height; // in cm
  late double weight; // in kg
  late int age;
  late double activityLevel; // Multiplier like 1.2, 1.55, etc.
  late double bmrTarget; // Calculated BMR goal
  late DateTime timestamp;
}
