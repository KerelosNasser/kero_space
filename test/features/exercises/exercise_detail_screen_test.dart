import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/exercises/data/repositories/exercises_repository.dart';
import 'package:kero_space/features/exercises/presentation/bloc/exercise_bloc.dart';
import 'package:kero_space/features/exercises/presentation/screens/exercise_detail_screen.dart';

class StubExerciseBloc extends Fake implements ExerciseBloc {
  final List<LogExerciseSet> loggedEvents = [];

  @override
  void add(ExerciseEvent event) {
    if (event is LogExerciseSet) {
      loggedEvents.add(event);
    }
  }

  @override
  Stream<ExerciseState> get stream => const Stream.empty();

  @override
  ExerciseState get state => const ExerciseState();
}

void main() {
  testWidgets('ExerciseDetailScreen renders details and logs set', (tester) async {
    final stubBloc = StubExerciseBloc();
    final exercise = WorkoutExerciseViewModel(
      id: 'ex-bench-01',
      name: 'Barbell Bench Press',
      category: 'chest',
      equipment: 'barbell',
      targetReps: '8-12',
      suggestedSets: 3,
      instructionsEn: 'Lie flat on bench. Grip bar evenly. Press upward.',
      loggedSets: [
        LoggedExerciseSet(
          exerciseId: 'ex-bench-01',
          exerciseName: 'Barbell Bench Press',
          setNumber: 1,
          reps: 10,
          weight: 70.0,
          loggedAt: DateTime(2026, 9, 5, 10, 0),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ExerciseBloc>.value(
          value: stubBloc,
          child: ExerciseDetailScreen(exercise: exercise),
        ),
      ),
    );

    expect(find.text('Barbell Bench Press'), findsWidgets);
    expect(find.text('CHEST'), findsOneWidget);
    expect(find.text('barbell'), findsOneWidget);
    expect(find.text('3 Sets × 8-12'), findsOneWidget);
    expect(find.text('INSTRUCTIONS'), findsOneWidget);
    expect(find.text('Lie flat on bench. Grip bar evenly. Press upward.'), findsOneWidget);
    expect(find.text('70.0 kg × 10 reps'), findsOneWidget);

    // Enter reps and weight for set 2
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), '75.0');
    await tester.enterText(textFields.at(1), '8');
    await tester.pump();

    final logButton = find.text('Log Set #2');
    expect(logButton, findsOneWidget);

    await tester.tap(logButton);
    await tester.pump();

    expect(stubBloc.loggedEvents.length, 1);
    expect(stubBloc.loggedEvents.first.weight, 75.0);
    expect(stubBloc.loggedEvents.first.reps, 8);
    expect(stubBloc.loggedEvents.first.setNumber, 2);
  });
}
