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

// States
class ChurchState extends Equatable {
  final List<MassAttendance> attendances;
  final List<MinistryTask> tasks;
  
  const ChurchState({
    this.attendances = const [],
    this.tasks = const [],
  });

  ChurchState copyWith({
    List<MassAttendance>? attendances,
    List<MinistryTask>? tasks,
  }) {
    return ChurchState(
      attendances: attendances ?? this.attendances,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  List<Object?> get props => [attendances, tasks];
}

// Bloc
class ChurchBloc extends Bloc<ChurchEvent, ChurchState> {
  final ChurchRepository _repository;

  ChurchBloc(this._repository) : super(const ChurchState()) {
    on<LoadChurchData>((event, emit) async {
      final attendances = await _repository.getAttendances();
      final tasks = await _repository.getTasks();
      emit(state.copyWith(attendances: attendances, tasks: tasks));
    });

    on<MarkAttendanceEvent>((event, emit) async {
      await _repository.markAttendance(event.date, event.type);
      add(LoadChurchData());
    });

    on<UpdateServiceTaskEvent>((event, emit) async {
      await _repository.saveTask(event.task);
      add(LoadChurchData());
    });
  }
}
