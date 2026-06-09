import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/productivity_collections.dart';
import '../../data/repositories/productivity_repository.dart';

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
  }

  Future<void> _onLoadData(_LoadData event, Emitter<ProductivityState> emit) async {
    emit(const ProductivityState.loading());
    try {
      // 1. Run carry-forward logic
      await _repository.performCarryForwardLogic();

      // 2. Load all data
      final allTasks = await _repository.getAllTasks();
      final dailyChecklist = await _repository.getDailyChecklist();
      final allNotes = await _repository.getAllNotes();

      emit(ProductivityState.loaded(
        allTasks: allTasks,
        dailyChecklist: dailyChecklist,
        allNotes: allNotes,
      ));
    } catch (e) {
      emit(ProductivityState.error("Failed to load productivity data: \$e"));
    }
  }

  Future<void> _onCreateTask(_CreateTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveTask(event.task);
      add(const ProductivityEvent.loadData()); // Refresh state
    } catch (e) {
      emit(ProductivityState.error("Failed to create task: \$e"));
    }
  }

  Future<void> _onUpdateTask(_UpdateTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveTask(event.task);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error("Failed to update task: \$e"));
    }
  }

  Future<void> _onCompleteTask(_CompleteTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.completeTaskRecursively(event.taskId);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error("Failed to complete task: \$e"));
    }
  }

  Future<void> _onDeleteTask(_DeleteTask event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.deleteTaskRecursively(event.taskId);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error("Failed to delete task: \$e"));
    }
  }

  Future<void> _onCreateNote(_CreateNote event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveNote(event.note);
      
      // If linked to a task, update the task
      if (event.linkedTaskId != null) {
        final allTasks = await _repository.getAllTasks();
        final task = allTasks.firstWhere((t) => t.id == event.linkedTaskId);
        task.linkedNoteId = event.note.id;
        await _repository.saveTask(task);
      }
      
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error("Failed to create note: \$e"));
    }
  }

  Future<void> _onUpdateNote(_UpdateNote event, Emitter<ProductivityState> emit) async {
    try {
      await _repository.saveNote(event.note);
      add(const ProductivityEvent.loadData());
    } catch (e) {
      emit(ProductivityState.error("Failed to update note: \$e"));
    }
  }
}
