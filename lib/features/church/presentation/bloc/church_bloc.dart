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
  final ServiceType type;
  const MarkAttendanceEvent(this.date, this.type);
  @override
  List<Object?> get props => [date, type];
}

class DeleteAttendanceEvent extends ChurchEvent {
  final DateTime date;
  final ServiceType type;
  const DeleteAttendanceEvent(this.date, this.type);
  @override
  List<Object?> get props => [date, type];
}

class UpdateServiceTaskEvent extends ChurchEvent {
  final MinistryTask task;
  const UpdateServiceTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class AddTaskEvent extends ChurchEvent {
  final MinistryTask task;
  const AddTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

enum ChurchStatus { initial, loading, success, failure }

// States
class ChurchState extends Equatable {
  final ChurchStatus status;
  final List<MassAttendance> attendances;
  final List<MinistryTask> tasks;
  final int currentStreak;
  final int bestStreak;
  final String? errorMessage;

  const ChurchState({
    this.status = ChurchStatus.initial,
    this.attendances = const [],
    this.tasks = const [],
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.errorMessage,
  });

  ChurchState copyWith({
    ChurchStatus? status,
    List<MassAttendance>? attendances,
    List<MinistryTask>? tasks,
    int? currentStreak,
    int? bestStreak,
    bool clearError = false,
    String? errorMessage,
  }) {
    return ChurchState(
      status: status ?? this.status,
      attendances: attendances ?? this.attendances,
      tasks: tasks ?? this.tasks,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, attendances, tasks, currentStreak, bestStreak, errorMessage];
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
        final currentStreak = await _repository.getStreak();
        final bestStreak = await _repository.getBestStreak();
        emit(state.copyWith(
          status: ChurchStatus.success,
          attendances: attendances,
          tasks: tasks,
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          clearError: true,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to load church data.',
        ));
      }
    });

    on<MarkAttendanceEvent>((event, emit) async {
      final newAttendance = MassAttendance()
        ..date = DateTime(event.date.year, event.date.month, event.date.day)
        ..services = [event.type];

      final updatedAttendances =
          List<MassAttendance>.from(state.attendances)..add(newAttendance);
      emit(state.copyWith(
        attendances: updatedAttendances,
        status: ChurchStatus.success,
        clearError: true,
      ));

      try {
        await _repository.markAttendance(event.date, event.type);
        final currentStreak = await _repository.getStreak();
        final bestStreak = await _repository.getBestStreak();
        emit(state.copyWith(
            currentStreak: currentStreak, bestStreak: bestStreak));
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to save attendance.',
        ));
        add(LoadChurchData());
      }
    });

    on<DeleteAttendanceEvent>((event, emit) async {
      final updatedAttendances = state.attendances.map((a) {
        if (a.date ==
            DateTime(event.date.year, event.date.month, event.date.day)) {
          final newServices =
              a.services.where((s) => s != event.type).toList();
          if (newServices.isEmpty) return null;
          final copy = MassAttendance()
            ..id = a.id
            ..date = a.date
            ..services = newServices;
          return copy;
        }
        return a;
      }).whereType<MassAttendance>().toList();

      emit(state.copyWith(attendances: updatedAttendances));
      try {
        await _repository.deleteAttendance(event.date, event.type);
        final streak = await _repository.getStreak();
        emit(state.copyWith(currentStreak: streak));
      } catch (e) {
        add(LoadChurchData());
      }
    });

    on<UpdateServiceTaskEvent>((event, emit) async {
      final updatedTasks = state.tasks
          .map((t) => t.id == event.task.id ? event.task : t)
          .toList();
      emit(state.copyWith(
          tasks: updatedTasks,
          status: ChurchStatus.success,
          clearError: true));
      try {
        await _repository.saveTask(event.task);
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to update task.',
        ));
        add(LoadChurchData());
      }
    });

    on<AddTaskEvent>((event, emit) async {
      final updatedTasks =
          List<MinistryTask>.from(state.tasks)..add(event.task);
      emit(state.copyWith(
          tasks: updatedTasks,
          status: ChurchStatus.success,
          clearError: true));
      try {
        await _repository.saveTask(event.task);
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to add task.',
        ));
        add(LoadChurchData());
      }
    });
  }
}
