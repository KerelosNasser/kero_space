import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/productivity/data/models/productivity_collections.dart';
import 'package:kero_space/features/productivity/data/repositories/productivity_repository.dart';
import 'package:kero_space/features/productivity/presentation/bloc/productivity_bloc.dart';

class FakeProductivityRepository extends ProductivityRepository {
  final List<Task> tasks = [];
  final List<Note> notes = [];

  @override
  Future<void> performCarryForwardLogic() async {}

  @override
  Future<List<Task>> getAllTasks() async => List.from(tasks);

  @override
  Future<List<Task>> getDailyChecklist() async => List.from(tasks);

  @override
  Future<List<Note>> getAllNotes() async => List.from(notes);

  @override
  Future<void> uncompleteTask(int taskId) async {
    final task = tasks.firstWhere((t) => t.id == taskId);
    task.isCompleted = false;
  }

  @override
  Future<void> deleteNote(int noteId) async {
    notes.removeWhere((n) => n.id == noteId);
  }
}

void main() {
  group('ProductivityBloc new events', () {
    late FakeProductivityRepository repository;
    late ProductivityBloc bloc;

    setUp(() {
      repository = FakeProductivityRepository();
      bloc = ProductivityBloc(repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('uncompleteTask marks task not completed and reloads state', () async {
      final task = Task()
        ..id = 42
        ..title = 'Workout'
        ..isCompleted = true;
      repository.tasks.add(task);

      bloc.add(const ProductivityEvent.uncompleteTask(42));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const ProductivityState.loading(),
          predicate<ProductivityState>((state) {
            return state.maybeWhen(
              loaded: (allTasks, checklist, notes) {
                return checklist.isNotEmpty && checklist.first.isCompleted == false;
              },
              orElse: () => false,
            );
          }),
        ]),
      );
    });

    test('deleteNote removes note from repository and reloads state', () async {
      final note = Note()
        ..id = 101
        ..title = 'Shopping List'
        ..quillDelta = '[]';
      repository.notes.add(note);

      bloc.add(const ProductivityEvent.deleteNote(101));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const ProductivityState.loading(),
          predicate<ProductivityState>((state) {
            return state.maybeWhen(
              loaded: (allTasks, checklist, notes) {
                return notes.isEmpty;
              },
              orElse: () => false,
            );
          }),
        ]),
      );
    });
  });
}
