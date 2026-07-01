import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.target,
    required this.secondaryMuscles,
    required this.instructionsEn,
  });

  final String id;
  final String name;
  final String category;
  final String equipment;
  final String target;
  final List<String> secondaryMuscles;
  final String instructionsEn;
}

class WorkoutSplitDefinition {
  const WorkoutSplitDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.daysPerWeek,
    required this.days,
  });

  final String id;
  final String name;
  final String description;
  final int daysPerWeek;
  final List<WorkoutDayDefinition> days;
}

class WorkoutDayDefinition {
  const WorkoutDayDefinition({
    required this.name,
    required this.sortOrder,
    required this.dayOfWeekMask,
    required this.focuses,
  });

  final String name;
  final int sortOrder;
  final int dayOfWeekMask;
  final List<String> focuses;
}

class LoggedExerciseSet {
  const LoggedExerciseSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.loggedAt,
  });

  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int reps;
  final double weight;
  final DateTime loggedAt;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory LoggedExerciseSet.fromJson(Map<String, dynamic> json) {
    return LoggedExerciseSet(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      setNumber: json['setNumber'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }
}

class WorkoutExerciseViewModel {
  const WorkoutExerciseViewModel({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.targetReps,
    required this.suggestedSets,
    required this.instructionsEn,
    required this.loggedSets,
  });

  final String id;
  final String name;
  final String category;
  final String equipment;
  final String targetReps;
  final int suggestedSets;
  final String instructionsEn;
  final List<LoggedExerciseSet> loggedSets;

  int get nextSetNumber => loggedSets.length + 1;
}

class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.splitName,
    required this.dayName,
    required this.date,
    required this.totalSets,
    required this.totalVolume,
  });

  final String splitName;
  final String dayName;
  final DateTime date;
  final int totalSets;
  final double totalVolume;
}

class TodayWorkoutViewModel {
  const TodayWorkoutViewModel({
    required this.dayName,
    required this.date,
    required this.exercises,
  });

  final String dayName;
  final DateTime date;
  final List<WorkoutExerciseViewModel> exercises;
}

class ExercisesDashboardData {
  const ExercisesDashboardData({
    required this.availableSplits,
    required this.selectedSplit,
    required this.todayWorkout,
    required this.history,
  });

  final List<WorkoutSplitDefinition> availableSplits;
  final WorkoutSplitDefinition selectedSplit;
  final TodayWorkoutViewModel todayWorkout;
  final List<WorkoutHistoryEntry> history;
}

@lazySingleton
class ExercisesRepository {
  static const _selectedSplitKey = 'exercise_selected_split_v1';
  static const _workoutLogsKey = 'exercise_workout_logs_v1';

  List<ExerciseDefinition>? _cache;

  static const List<WorkoutSplitDefinition> _defaultSplits = [
    WorkoutSplitDefinition(
      id: 'full-body',
      name: 'Full Body',
      description: 'Three balanced sessions across the week.',
      daysPerWeek: 3,
      days: [
        WorkoutDayDefinition(
          name: 'Full A',
          sortOrder: 1,
          dayOfWeekMask: 1,
          focuses: ['chest', 'back', 'upper legs', 'shoulders'],
        ),
        WorkoutDayDefinition(
          name: 'Full B',
          sortOrder: 2,
          dayOfWeekMask: 4,
          focuses: ['waist', 'upper arms', 'upper legs', 'cardio'],
        ),
        WorkoutDayDefinition(
          name: 'Full C',
          sortOrder: 3,
          dayOfWeekMask: 16,
          focuses: ['back', 'shoulders', 'waist', 'lower legs'],
        ),
      ],
    ),
    WorkoutSplitDefinition(
      id: 'upper-lower',
      name: 'Upper/Lower',
      description:
          'Alternating upper and lower emphasis with recovery built in.',
      daysPerWeek: 4,
      days: [
        WorkoutDayDefinition(
          name: 'Upper A',
          sortOrder: 1,
          dayOfWeekMask: 1,
          focuses: ['chest', 'back', 'shoulders'],
        ),
        WorkoutDayDefinition(
          name: 'Lower A',
          sortOrder: 2,
          dayOfWeekMask: 2,
          focuses: ['upper legs', 'lower legs', 'waist'],
        ),
        WorkoutDayDefinition(
          name: 'Upper B',
          sortOrder: 3,
          dayOfWeekMask: 8,
          focuses: ['back', 'upper arms', 'shoulders'],
        ),
        WorkoutDayDefinition(
          name: 'Lower B',
          sortOrder: 4,
          dayOfWeekMask: 16,
          focuses: ['upper legs', 'glutes', 'waist'],
        ),
      ],
    ),
    WorkoutSplitDefinition(
      id: 'bro-split',
      name: 'Bro Split',
      description: 'Classic five-day body-part focus.',
      daysPerWeek: 5,
      days: [
        WorkoutDayDefinition(
          name: 'Chest',
          sortOrder: 1,
          dayOfWeekMask: 1,
          focuses: ['chest'],
        ),
        WorkoutDayDefinition(
          name: 'Back',
          sortOrder: 2,
          dayOfWeekMask: 2,
          focuses: ['back'],
        ),
        WorkoutDayDefinition(
          name: 'Shoulders',
          sortOrder: 3,
          dayOfWeekMask: 4,
          focuses: ['shoulders'],
        ),
        WorkoutDayDefinition(
          name: 'Legs',
          sortOrder: 4,
          dayOfWeekMask: 8,
          focuses: ['upper legs', 'lower legs'],
        ),
        WorkoutDayDefinition(
          name: 'Arms',
          sortOrder: 5,
          dayOfWeekMask: 16,
          focuses: ['upper arms', 'lower arms'],
        ),
      ],
    ),
    WorkoutSplitDefinition(
      id: 'pplul',
      name: 'PPLUL',
      description: 'Push, pull, legs, then upper/lower finishers.',
      daysPerWeek: 5,
      days: [
        WorkoutDayDefinition(
          name: 'Push',
          sortOrder: 1,
          dayOfWeekMask: 1,
          focuses: ['chest', 'shoulders', 'upper arms'],
        ),
        WorkoutDayDefinition(
          name: 'Pull',
          sortOrder: 2,
          dayOfWeekMask: 2,
          focuses: ['back', 'upper arms'],
        ),
        WorkoutDayDefinition(
          name: 'Legs',
          sortOrder: 3,
          dayOfWeekMask: 4,
          focuses: ['upper legs', 'lower legs', 'glutes'],
        ),
        WorkoutDayDefinition(
          name: 'Upper',
          sortOrder: 4,
          dayOfWeekMask: 8,
          focuses: ['chest', 'back', 'shoulders'],
        ),
        WorkoutDayDefinition(
          name: 'Lower',
          sortOrder: 5,
          dayOfWeekMask: 16,
          focuses: ['upper legs', 'lower legs', 'waist'],
        ),
      ],
    ),
    WorkoutSplitDefinition(
      id: 'ppl',
      name: 'PPL',
      description: 'Six-day push/pull/legs rotation with A/B variety.',
      daysPerWeek: 6,
      days: [
        WorkoutDayDefinition(
          name: 'Push A',
          sortOrder: 1,
          dayOfWeekMask: 1,
          focuses: ['chest', 'shoulders', 'upper arms'],
        ),
        WorkoutDayDefinition(
          name: 'Pull A',
          sortOrder: 2,
          dayOfWeekMask: 2,
          focuses: ['back', 'upper arms'],
        ),
        WorkoutDayDefinition(
          name: 'Legs A',
          sortOrder: 3,
          dayOfWeekMask: 4,
          focuses: ['upper legs', 'glutes', 'waist'],
        ),
        WorkoutDayDefinition(
          name: 'Push B',
          sortOrder: 4,
          dayOfWeekMask: 8,
          focuses: ['chest', 'shoulders', 'upper arms'],
        ),
        WorkoutDayDefinition(
          name: 'Pull B',
          sortOrder: 5,
          dayOfWeekMask: 16,
          focuses: ['back', 'lower arms'],
        ),
        WorkoutDayDefinition(
          name: 'Legs B',
          sortOrder: 6,
          dayOfWeekMask: 32,
          focuses: ['upper legs', 'lower legs', 'waist'],
        ),
      ],
    ),
    WorkoutSplitDefinition(
      id: 'arnold',
      name: 'Arnold Split',
      description:
          'Chest/back, shoulders/arms, and legs repeated twice weekly.',
      daysPerWeek: 6,
      days: [
        WorkoutDayDefinition(
          name: 'Chest + Back A',
          sortOrder: 1,
          dayOfWeekMask: 1,
          focuses: ['chest', 'back'],
        ),
        WorkoutDayDefinition(
          name: 'Shoulders + Arms A',
          sortOrder: 2,
          dayOfWeekMask: 2,
          focuses: ['shoulders', 'upper arms'],
        ),
        WorkoutDayDefinition(
          name: 'Legs A',
          sortOrder: 3,
          dayOfWeekMask: 4,
          focuses: ['upper legs', 'lower legs', 'glutes'],
        ),
        WorkoutDayDefinition(
          name: 'Chest + Back B',
          sortOrder: 4,
          dayOfWeekMask: 8,
          focuses: ['chest', 'back'],
        ),
        WorkoutDayDefinition(
          name: 'Shoulders + Arms B',
          sortOrder: 5,
          dayOfWeekMask: 16,
          focuses: ['shoulders', 'upper arms'],
        ),
        WorkoutDayDefinition(
          name: 'Legs B',
          sortOrder: 6,
          dayOfWeekMask: 32,
          focuses: ['upper legs', 'lower legs', 'waist'],
        ),
      ],
    ),
  ];

  Future<ExercisesDashboardData> loadDashboard({
    String? preferredSplitName,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = now ?? DateTime.now();
    final splitName =
        preferredSplitName ??
        prefs.getString(_selectedSplitKey) ??
        _defaultSplits.first.name;

    final split = _defaultSplits.firstWhere(
      (item) => item.name == splitName,
      orElse: () => _defaultSplits.first,
    );

    final exercises = await _loadExercises();
    final day = resolveDayForDate(split, current);
    final logs = await _readLogs();
    final todayLogs = _logsForDay(logs, split.name, day.name, current);
    final todayExercises = _buildWorkoutExercises(exercises, day, todayLogs);
    final history = _buildHistory(logs, split.name);

    return ExercisesDashboardData(
      availableSplits: _defaultSplits,
      selectedSplit: split,
      todayWorkout: TodayWorkoutViewModel(
        dayName: day.name,
        date: current,
        exercises: todayExercises,
      ),
      history: history,
    );
  }

  Future<void> saveSelectedSplit(String splitName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSplitKey, splitName);
  }

  Future<void> logSet({
    required String splitName,
    required String dayName,
    required DateTime date,
    required String exerciseId,
    required String exerciseName,
    required int setNumber,
    required int reps,
    required double weight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await _readLogs();
    logs.add({
      'splitName': splitName,
      'dayName': dayName,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'set': LoggedExerciseSet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        setNumber: setNumber,
        reps: reps,
        weight: weight,
        loggedAt: DateTime.now(),
      ).toJson(),
    });
    await prefs.setString(_workoutLogsKey, jsonEncode(logs));
  }

  Future<List<ExerciseDefinition>> _loadExercises() async {
    if (_cache != null) {
      return _cache!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/exercises_seed.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    _cache = decoded
        .whereType<Map<String, dynamic>>()
        .map(mapExerciseFromSeed)
        .where((exercise) => exercise.name.trim().isNotEmpty)
        .toList(growable: false);
    return _cache!;
  }

  @visibleForTesting
  static ExerciseDefinition mapExerciseFromSeed(Map<String, dynamic> json) {
    final instructions = json['instructions'];
    final instructionSteps = json['instruction_steps'];
    final secondaryMuscles =
        json['secondaryMuscles'] ?? json['secondary_muscles'];

    return ExerciseDefinition(
      id: (json['id'] ?? json['name']).toString(),
      name: (json['name'] as String?)?.trim() ?? '',
      category:
          ((json['body_part'] ?? json['category'] ?? json['target'])
                      as String? ??
                  'general')
              .toLowerCase(),
      equipment: (json['equipment'] as String?)?.trim() ?? 'body weight',
      target:
          ((json['target'] ?? json['body_part'] ?? json['category'])
                      as String? ??
                  'general')
              .toLowerCase(),
      secondaryMuscles: secondaryMuscles is List
          ? secondaryMuscles
                .map((item) => item.toString())
                .toList(growable: false)
          : const [],
      instructionsEn: extractEnglishInstructions(
        instructions,
        instructionSteps,
      ),
    );
  }

  @visibleForTesting
  static String extractEnglishInstructions(
    dynamic instructions,
    dynamic instructionSteps,
  ) {
    if (instructions is Map<String, dynamic>) {
      final english = instructions['en'];
      if (english is String && english.trim().isNotEmpty) {
        return english.trim();
      }
    }

    if (instructionSteps is Map<String, dynamic>) {
      final englishSteps = instructionSteps['en'];
      if (englishSteps is List) {
        final joined = englishSteps
            .map((step) => step.toString().trim())
            .where((step) => step.isNotEmpty)
            .join(' ');
        if (joined.isNotEmpty) {
          return joined;
        }
      }
    }

    return 'Move with control and focus on the target muscle group.';
  }

  @visibleForTesting
  static WorkoutDayDefinition resolveDayForDate(
    WorkoutSplitDefinition split,
    DateTime date,
  ) {
    final mask = 1 << (date.weekday - 1);
    for (final day in split.days) {
      if ((day.dayOfWeekMask & mask) != 0) {
        return day;
      }
    }
    return split.days[(date.weekday - 1) % split.days.length];
  }

  List<WorkoutExerciseViewModel> _buildWorkoutExercises(
    List<ExerciseDefinition> exercises,
    WorkoutDayDefinition day,
    List<LoggedExerciseSet> logs,
  ) {
    final selected = <ExerciseDefinition>[];
    final usedIds = <String>{};

    for (final focus in day.focuses) {
      final matches = exercises
          .where((exercise) {
            final haystack = <String>[
              exercise.category,
              exercise.target,
              ...exercise.secondaryMuscles.map((item) => item.toLowerCase()),
            ];
            return haystack.any((value) => value.contains(focus));
          })
          .take(2);

      for (final match in matches) {
        if (usedIds.add(match.id)) {
          selected.add(match);
        }
      }
    }

    if (selected.length < 6) {
      for (final fallback in exercises.take(30)) {
        if (usedIds.add(fallback.id)) {
          selected.add(fallback);
        }
        if (selected.length >= 6) {
          break;
        }
      }
    }

    return selected
        .take(8)
        .map((exercise) {
          final exerciseLogs =
              logs.where((log) => log.exerciseId == exercise.id).toList()
                ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
          return WorkoutExerciseViewModel(
            id: exercise.id,
            name: exercise.name,
            category: _titleCase(exercise.category),
            equipment: exercise.equipment,
            targetReps: _targetRepsForCategory(exercise.category),
            suggestedSets: _suggestedSetsForCategory(exercise.category),
            instructionsEn: exercise.instructionsEn,
            loggedSets: exerciseLogs,
          );
        })
        .toList(growable: false);
  }

  List<LoggedExerciseSet> _logsForDay(
    List<Map<String, dynamic>> logs,
    String splitName,
    String dayName,
    DateTime date,
  ) {
    final normalized = DateTime(date.year, date.month, date.day);
    return logs
        .where((log) {
          return log['splitName'] == splitName &&
              log['dayName'] == dayName &&
              DateTime.parse(log['date'] as String) == normalized;
        })
        .map((log) {
          return LoggedExerciseSet.fromJson(log['set'] as Map<String, dynamic>);
        })
        .toList(growable: false);
  }

  List<WorkoutHistoryEntry> _buildHistory(
    List<Map<String, dynamic>> logs,
    String splitName,
  ) {
    final grouped = <String, List<LoggedExerciseSet>>{};
    final dates = <String, DateTime>{};
    final dayNames = <String, String>{};

    for (final log in logs) {
      if (log['splitName'] != splitName) {
        continue;
      }

      final date = DateTime.parse(log['date'] as String);
      final dayName = log['dayName'] as String;
      final key = '${date.toIso8601String()}::$dayName';

      grouped
          .putIfAbsent(key, () => [])
          .add(LoggedExerciseSet.fromJson(log['set'] as Map<String, dynamic>));
      dates[key] = date;
      dayNames[key] = dayName;
    }

    final history = grouped.entries.map((entry) {
      final sets = entry.value;
      final totalVolume = sets.fold<double>(
        0,
        (sum, item) => sum + (item.reps * item.weight),
      );
      return WorkoutHistoryEntry(
        splitName: splitName,
        dayName: dayNames[entry.key] ?? 'Workout',
        date: dates[entry.key]!,
        totalSets: sets.length,
        totalVolume: totalVolume,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return history.take(7).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _readLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workoutLogsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map<String, dynamic>>().toList(growable: true);
    } catch (error, stackTrace) {
      debugPrint('Failed to decode exercise logs: $error\n$stackTrace');
      return <Map<String, dynamic>>[];
    }
  }

  String _targetRepsForCategory(String category) {
    if (category.contains('waist') || category.contains('cardio')) {
      return '12-20';
    }
    if (category.contains('upper legs') || category.contains('glutes')) {
      return '6-10';
    }
    return '8-12';
  }

  int _suggestedSetsForCategory(String category) {
    if (category.contains('waist') || category.contains('cardio')) {
      return 3;
    }
    return 4;
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
