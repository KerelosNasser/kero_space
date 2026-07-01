import 'package:isar/isar.dart';

part 'exercise_collections.g.dart';

@collection
class Exercise {
  Id id = Isar.autoIncrement;
  @Index()
  late String name;
  @Index()
  late String category;
  late String equipment;
  @Index()
  late String target;
  late String muscleGroup;
  late String secondaryMuscles;
  late String instructionsEn;
}

@collection
class WorkoutSplit {
  Id id = Isar.autoIncrement;
  late String name;
  late String description;
  late int daysPerWeek;
  @Index()
  late int sortOrder;
}

@collection
class WorkoutDay {
  Id id = Isar.autoIncrement;
  @Index()
  late int splitId;
  late String dayName;
  late int dayOfWeekMask;
  late int sortOrder;
}

@collection
class WorkoutDayExercise {
  Id id = Isar.autoIncrement;
  @Index()
  late int dayId;
  @Index()
  late int exerciseId;
  late int sets;
  late String targetReps;
  late int sortOrder;
}

@collection
class WorkoutLog {
  Id id = Isar.autoIncrement;
  @Index()
  late int splitId;
  @Index()
  late DateTime date;
  late int dayId;
  String? notes;
}

@collection
class WorkoutSet {
  Id id = Isar.autoIncrement;
  @Index()
  late int logId;
  late int dayExerciseId;
  late int setNumber;
  late int reps;
  late double weight;
}
