import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/productivity_collections.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/services/ai_service.dart';

part 'productivity_event.dart';
part 'productivity_state.dart';
part 'productivity_bloc.freezed.dart';

@injectable
class ProductivityBloc extends Bloc<ProductivityEvent, ProductivityState> {
  final ProductivityRepository _repository;

  ProductivityBloc(this._repository) : super(const ProductivityState.loading()) {
    on<_LoadData>(_onLoadData);
    on<_CreateTask>(_onCreateTask);
    on<_UpdateTask>(_onUpdateTask);
    on<_CompleteTask>(_onCompleteTask);
    on<_DeleteTask>(_onDeleteTask);
    on<_CreateNote>(_onCreateNote);
    on<_UpdateNote>(_onUpdateNote);
    on<_CreateProjectWithSubtasks>(_onCreateProjectWithSubtasks);
    on<_AutoScheduleTasks>(_onAutoScheduleTasks);
  }

  Future<void> _onLoadData(_LoadData event, Emitter<ProductivityState> emit) async {
    emit(const ProductivityState.loading());
    try {
      await _repository.performCarryForwardLogic();

      final allTasks = await _repository.getAllTasks();
      final dailyChecklist = await _repository.getDailyChecklist();
      final allNotes = await _repository.getAllNotes();

      emit(ProductivityState.loaded(
        allTasks: allTasks,
        dailyChecklist: dailyChecklist,
        allNotes: allNotes,
      ));
    } catch (e) {
      emit(ProductivityState.error('Failed to load. Please try again.'));
    }
  }

  Future<void> _onCreateTask(_CreateTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveTask(event.task);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to save. Please try again.'));
    }
  }

  Future<void> _onUpdateTask(_UpdateTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveTask(event.task);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to save. Please try again.'));
    }
  }

  Future<void> _onCompleteTask(_CompleteTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.completeTaskRecursively(event.taskId);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to save. Please try again.'));
    }
  }

  Future<void> _onDeleteTask(_DeleteTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.deleteTaskRecursively(event.taskId);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to save. Please try again.'));
    }
  }

  Future<void> _onCreateNote(_CreateNote event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveNote(event.note);

      if (event.linkedTaskId != null) {
        final allTasks = await _repository.getAllTasks();
        final task = allTasks.firstWhere(
          (t) => t.id == event.linkedTaskId,
          orElse: () => Task(),
        );
        if (task.id != 0) {
          task.linkedNoteId = event.note.id;
          await _repository.saveTask(task);
        }
      }

      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to save. Please try again.'));
    }
  }

  Future<void> _onUpdateNote(_UpdateNote event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveNote(event.note);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to save. Please try again.'));
    }
  }

  Future<void> _onCreateProjectWithSubtasks(_CreateProjectWithSubtasks event, Emitter<ProductivityState> emit) async {
    try {
      final project = Task()
        ..title = event.title
        ..icon = event.icon
        ..type = TaskType.project
        ..deviceId = 'local'
        ..platform = 'local'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      
      await _repository.saveTask(project);

      for (var sub in event.subtasks) {
        final subtask = Task()
          ..title = sub['title']
          ..energyLevel = sub['energyLevel']
          ..type = TaskType.task
          ..parentId = project.id
          ..deviceId = 'local'
          ..platform = 'local'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _repository.saveTask(subtask);
      }

      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to save AI project.'));
    }
  }

  Future<void> _onAutoScheduleTasks(_AutoScheduleTasks event, Emitter<ProductivityState> emit) async {
    try {
      final allTasks = await _repository.getAllTasks();
      final unscheduled = allTasks.where((t) => !t.isCompleted && t.dueDate == null).toList();
      
      if (unscheduled.isEmpty) return;

      final aiService = AIService();
      final mappedTasks = unscheduled.map((t) => {'id': t.id, 'title': t.title, 'energyLevel': t.energyLevel}).toList();
      final schedule = await aiService.autoScheduleTasks(mappedTasks);

      for (var task in unscheduled) {
        if (schedule.containsKey(task.id)) {
          task.dueDate = schedule[task.id];
          await _repository.saveTask(task);
        }
      }

      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error('Failed to auto-schedule tasks.'));
    }
  }
}
