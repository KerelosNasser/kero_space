part of 'productivity_bloc.dart';

@freezed
class ProductivityState with _$ProductivityState {
  const factory ProductivityState.loading() = _Loading;
  const factory ProductivityState.loaded({
    required List<Task> allTasks, // Used to build the tree
    required List<Task> dailyChecklist,
    required List<Note> allNotes,
  }) = _Loaded;
  const factory ProductivityState.error(String message) = _Error;
}
