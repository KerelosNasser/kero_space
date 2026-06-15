import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/church_repository.dart';
import '../../data/models/mass_attendance.dart';
import '../../data/models/ministry_task.dart';

// Events
abstract class ChurchEvent extends Equatable {
  const ChurchEvent();
  @override
  List<Object?> get props => [];
}

class LoadChurchData extends ChurchEvent {}

class MarkAttendanceEvent extends ChurchEvent {
  final DateTime date;
  final AttendanceType type;
  const MarkAttendanceEvent(this.date, this.type);
  @override
  List<Object?> get props => [date, type];
}

class UpdateServiceTaskEvent extends ChurchEvent {
  final MinistryTask task;
  const UpdateServiceTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

enum ChurchStatus { initial, loading, success, failure }

// States
class ChurchState extends Equatable {
  final ChurchStatus status;
  final List<MassAttendance> attendances;
  final List<MinistryTask> tasks;
  final String? errorMessage;
  
  const ChurchState({
    this.status = ChurchStatus.initial,
    this.attendances = const [],
    this.tasks = const [],
    this.errorMessage,
  });

  ChurchState copyWith({
    ChurchStatus? status,
    List<MassAttendance>? attendances,
    List<MinistryTask>? tasks,
    bool clearError = false,
    String? errorMessage,
  }) {
    return ChurchState(
      status: status ?? this.status,
      attendances: attendances ?? this.attendances,
      tasks: tasks ?? this.tasks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, attendances, tasks, errorMessage];
}

// Bloc
class ChurchBloc extends Bloc<ChurchEvent, ChurchState> {
  final ChurchRepository _repository;

  ChurchBloc(this._repository) : super(const ChurchState()) {
    on<LoadChurchData>((event, emit) async {
      emit(state.copyWith(status: ChurchStatus.loading));
      try {
        final attendances = await _repository.getAttendances();
        final tasks = await _repository.getTasks();
        emit(state.copyWith(
          status: ChurchStatus.success,
          attendances: attendances,
          tasks: tasks,
          clearError: true,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: "Failed to load church data.",
        ));
      }
    });

    on<MarkAttendanceEvent>((event, emit) async {
      // Optimistic UI update
      final newAttendance = MassAttendance()
        ..date = DateTime(event.date.year, event.date.month, event.date.day)
        ..attendanceType = event.type;
        
      final updatedAttendances = List<MassAttendance>.from(state.attendances)..add(newAttendance);
      emit(state.copyWith(attendances: updatedAttendances, status: ChurchStatus.success, clearError: true));
      
      try {
        await _repository.markAttendance(event.date, event.type);
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: "Failed to save attendance.",
        ));
        add(LoadChurchData()); // Revert optimistic update
      }
    });

    on<UpdateServiceTaskEvent>((event, emit) async {
      // Optimistic update
      final updatedTasks = state.tasks.map((t) => t.id == event.task.id ? event.task : t).toList();
      emit(state.copyWith(tasks: updatedTasks, status: ChurchStatus.success, clearError: true));

      try {
        await _repository.saveTask(event.task);
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: "Failed to update task.",
        ));
        add(LoadChurchData()); // Revert optimistic update
      }
    });
  }
}
