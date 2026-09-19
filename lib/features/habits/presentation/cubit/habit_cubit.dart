import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';

class HabitState {
  final bool isLoading;
  final List<Habit> habits;
  final String? errorMessage;

  const HabitState({
    this.isLoading = false,
    this.habits = const [],
    this.errorMessage,
  });

  int get completedTodayCount => habits.where((h) => h.isCompletedToday).length;
  int get totalHabitsCount => habits.length;
  double get completionRate =>
      totalHabitsCount > 0 ? (completedTodayCount / totalHabitsCount) : 0.0;

  HabitState copyWith({
    bool? isLoading,
    List<Habit>? habits,
    String? errorMessage,
  }) {
    return HabitState(
      isLoading: isLoading ?? this.isLoading,
      habits: habits ?? this.habits,
      errorMessage: errorMessage,
    );
  }
}

class HabitCubit extends Cubit<HabitState> {
  final HabitRepository _repository;

  HabitCubit({HabitRepository? repository})
      : _repository = repository ?? HabitRepository(),
        super(const HabitState(isLoading: true));

  Future<void> loadHabits() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final habits = await _repository.getHabits();
      emit(state.copyWith(isLoading: false, habits: habits));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> toggleHabit(String habitId) async {
    try {
      await _repository.toggleHabitToday(habitId);
      final updated = await _repository.getHabits();
      emit(state.copyWith(habits: updated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _repository.addHabit(habit);
      final updated = await _repository.getHabits();
      emit(state.copyWith(habits: updated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      final updated = await _repository.getHabits();
      emit(state.copyWith(habits: updated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
