part of 'productivity_bloc.dart';

@freezed
class ProductivityEvent with _$ProductivityEvent {
  const factory ProductivityEvent.loadData() = _LoadData;
  const factory ProductivityEvent.createTask(Task task) = _CreateTask;
  const factory ProductivityEvent.updateTask(Task task) = _UpdateTask;
  const factory ProductivityEvent.completeTask(int taskId) = _CompleteTask;
  const factory ProductivityEvent.deleteTask(int taskId) = _DeleteTask;
  
  const factory ProductivityEvent.createNote(Note note, {int? linkedTaskId}) = _CreateNote;
  const factory ProductivityEvent.updateNote(Note note) = _UpdateNote;

  const factory ProductivityEvent.createProjectWithSubtasks(String title, String? icon, List<dynamic> subtasks) = _CreateProjectWithSubtasks;
  const factory ProductivityEvent.autoScheduleTasks() = _AutoScheduleTasks;
}
