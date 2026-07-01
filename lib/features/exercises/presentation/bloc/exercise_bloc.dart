import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:kero_space/features/exercises/data/repositories/exercises_repository.dart';

part 'exercise_event.dart';
part 'exercise_state.dart';

@injectable
class ExerciseBloc extends Bloc<ExerciseEvent, ExerciseState> {
  ExerciseBloc(this._repository) : super(const ExerciseState()) {
    on<LoadExercisesDashboard>(_onLoadExercisesDashboard);
    on<SelectExerciseSplit>(_onSelectExerciseSplit);
    on<LogExerciseSet>(_onLogExerciseSet);
  }

  final ExercisesRepository _repository;

  Future<void> _onLoadExercisesDashboard(
    LoadExercisesDashboard event,
    Emitter<ExerciseState> emit,
  ) async {
    emit(state.copyWith(status: ExerciseStatus.loading, errorMessage: null));
    try {
      final data = await _repository.loadDashboard(
        preferredSplitName: event.preferredSplitName,
      );
      emit(
        state.copyWith(
          status: ExerciseStatus.success,
          availableSplits: data.availableSplits,
          selectedSplit: data.selectedSplit,
          todayWorkout: data.todayWorkout,
          history: data.history,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ExerciseStatus.failure,
          errorMessage: 'Failed to load exercises.',
        ),
      );
    }
  }

  Future<void> _onSelectExerciseSplit(
    SelectExerciseSplit event,
    Emitter<ExerciseState> emit,
  ) async {
    await _repository.saveSelectedSplit(event.splitName);
    add(LoadExercisesDashboard(preferredSplitName: event.splitName));
  }

  Future<void> _onLogExerciseSet(
    LogExerciseSet event,
    Emitter<ExerciseState> emit,
  ) async {
    final selectedSplit = state.selectedSplit;
    final todayWorkout = state.todayWorkout;
    if (selectedSplit == null || todayWorkout == null) {
      return;
    }

    try {
      await _repository.logSet(
        splitName: selectedSplit.name,
        dayName: todayWorkout.dayName,
        date: todayWorkout.date,
        exerciseId: event.exerciseId,
        exerciseName: event.exerciseName,
        setNumber: event.setNumber,
        reps: event.reps,
        weight: event.weight,
      );
      add(LoadExercisesDashboard(preferredSplitName: selectedSplit.name));
    } catch (error) {
      emit(
        state.copyWith(
          status: ExerciseStatus.failure,
          errorMessage: 'Failed to save workout set.',
        ),
      );
    }
  }
}
