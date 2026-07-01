part of 'exercise_bloc.dart';

enum ExerciseStatus { initial, loading, success, failure }

class ExerciseState extends Equatable {
  const ExerciseState({
    this.status = ExerciseStatus.initial,
    this.availableSplits = const [],
    this.selectedSplit,
    this.todayWorkout,
    this.history = const [],
    this.errorMessage,
  });

  final ExerciseStatus status;
  final List<WorkoutSplitDefinition> availableSplits;
  final WorkoutSplitDefinition? selectedSplit;
  final TodayWorkoutViewModel? todayWorkout;
  final List<WorkoutHistoryEntry> history;
  final String? errorMessage;

  ExerciseState copyWith({
    ExerciseStatus? status,
    List<WorkoutSplitDefinition>? availableSplits,
    WorkoutSplitDefinition? selectedSplit,
    TodayWorkoutViewModel? todayWorkout,
    List<WorkoutHistoryEntry>? history,
    Object? errorMessage = _sentinel,
  }) {
    return ExerciseState(
      status: status ?? this.status,
      availableSplits: availableSplits ?? this.availableSplits,
      selectedSplit: selectedSplit ?? this.selectedSplit,
      todayWorkout: todayWorkout ?? this.todayWorkout,
      history: history ?? this.history,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
    status,
    availableSplits,
    selectedSplit,
    todayWorkout,
    history,
    errorMessage,
  ];
}
