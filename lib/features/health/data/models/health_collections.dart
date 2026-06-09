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
