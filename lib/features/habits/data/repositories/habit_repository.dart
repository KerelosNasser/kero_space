import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data/isar_service.dart';
import '../../../../core/data/sync_outbox_record.dart';
import '../../../../core/data/sync_outbox_repository.dart';
import '../models/habit_model.dart';

class HabitRepository {
  static const _storageKey = 'trobio_user_habits_json';
  final SharedPreferences? _prefsInstance;
  final SyncOutboxRepository? outboxRepo;

  HabitRepository({
    SharedPreferences? prefs,
    this.outboxRepo,
  }) : _prefsInstance = prefs;

  Future<SharedPreferences> get _prefs async =>
      _prefsInstance ?? await SharedPreferences.getInstance();

  static List<Habit> get defaultStarterPack => [
    const Habit(
      id: 'detox-morning-01',
      title: 'Morning Phone-Free (30m)',
      description: 'No screens for first 30 mins after waking',
      category: HabitCategory.detox,
      colorValue: 0xFF26A69A, // Teal
      iconCode: 'alarm_off',
    ),
    const Habit(
      id: 'detox-water-02',
      title: 'Drink 500ml Water First',
      description: 'Hydrate before touching social media or news',
      category: HabitCategory.health,
      colorValue: 0xFF42A5F5, // Blue
      iconCode: 'water_drop',
    ),
    const Habit(
      id: 'detox-reading-03',
      title: 'Read 10 Pages Before Scrolling',
      description: 'Read a physical book or Kindle before opening feeds',
      category: HabitCategory.mind,
      colorValue: 0xFFAB47BC, // Purple
      iconCode: 'menu_book',
    ),
    const Habit(
      id: 'detox-walk-04',
      title: '15-Min Screen-Free Walk',
      description: 'Walk outside leaving phone in pocket',
      category: HabitCategory.focus,
      colorValue: 0xFF66BB6A, // Green
      iconCode: 'directions_walk',
    ),
    const Habit(
      id: 'detox-night-05',
      title: 'Bedtime Screen Curfew (1h)',
      description: 'Zero screens 1 hour before going to sleep',
      category: HabitCategory.detox,
      colorValue: 0xFFFFA726, // Orange
      iconCode: 'bedtime',
    ),
  ];

  Future<List<Habit>> getHabits() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Seed default phone detox starter pack
      await saveAll(defaultStarterPack);
      return defaultStarterPack;
    }

    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaultStarterPack;
    }
  }

  Future<void> saveAll(List<Habit> habits) async {
    final prefs = await _prefs;
    final jsonStr = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  Future<Habit?> toggleHabitToday(String habitId) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return null;

    final habit = habits[index];
    final todayKey = Habit.formatDateKey(DateTime.now());
    final newDates = Set<String>.from(habit.completedDates);

    if (newDates.contains(todayKey)) {
      newDates.remove(todayKey);
    } else {
      newDates.add(todayKey);
    }

    final newStreak = Habit.calculateStreak(newDates, DateTime.now());
    final newBest = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

    final updated = habit.copyWith(
      completedDates: newDates,
      streakCount: newStreak,
      bestStreak: newBest,
    );

    habits[index] = updated;
    await saveAll(habits);
    await _queueOutbox(
      entityId: updated.id,
      operation: 'UPDATE',
      payload: updated.toJson(),
    );
    return updated;
  }

  Future<void> addHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveAll(habits);
    await _queueOutbox(
      entityId: habit.id,
      operation: 'CREATE',
      payload: habit.toJson(),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await getHabits();
    habits.removeWhere((h) => h.id == habitId);
    await saveAll(habits);
    await _queueOutbox(
      entityId: habitId,
      operation: 'DELETE',
      payload: {'id': habitId},
    );
  }

  Future<void> _queueOutbox({
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final repo = outboxRepo ?? (IsarService.isInitialized ? SyncOutboxRepository() : null);
      if (repo != null) {
        await repo.addToOutbox(
          SyncOutboxRecord()
            ..entityId = entityId
            ..collectionName = 'habits'
            ..operation = operation
            ..payloadJson = jsonEncode(payload)
            ..createdAt = DateTime.now()
            ..status = 'PENDING',
        );
      }
    } catch (_) {
      // Local storage in SharedPreferences remains intact if outbox queue fails
    }
  }
}

