part of 'exercise_bloc.dart';

sealed class ExerciseEvent extends Equatable {
  const ExerciseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExercisesDashboard extends ExerciseEvent {
  const LoadExercisesDashboard({this.preferredSplitName});

  final String? preferredSplitName;

  @override
  List<Object?> get props => [preferredSplitName];
}

class SelectExerciseSplit extends ExerciseEvent {
  const SelectExerciseSplit(this.splitName);

  final String splitName;

  @override
  List<Object?> get props => [splitName];
}

class LogExerciseSet extends ExerciseEvent {
  const LogExerciseSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int reps;
  final double weight;

  @override
  List<Object?> get props => [
    exerciseId,
    exerciseName,
    setNumber,
    reps,
    weight,
  ];
}
