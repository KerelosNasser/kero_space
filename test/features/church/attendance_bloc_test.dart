import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/church/data/models/mass_attendance.dart';
import 'package:kero_space/features/church/data/models/ministry_task.dart';
import 'package:kero_space/features/church/data/repositories/church_repository.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';

class FakeChurchRepository implements ChurchRepository {
  final List<MassAttendance> attendances = [];
  final List<MinistryTask> tasks = [];
  int streak = 0;
  int bestStreak = 0;

  @override
  Future<void> markAttendance(DateTime date, ServiceType type) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final idx = attendances.indexWhere((a) =>
        a.date.year == normalized.year &&
        a.date.month == normalized.month &&
        a.date.day == normalized.day);
    if (idx >= 0) {
      if (!attendances[idx].services.contains(type)) {
        attendances[idx].services = [...attendances[idx].services, type];
      }
    } else {
      final item = MassAttendance()
        ..date = normalized
        ..services = [type];
      attendances.add(item);
    }
    streak = attendances.length;
    if (streak > bestStreak) bestStreak = streak;
  }

  @override
  Future<void> deleteAttendance(DateTime date, ServiceType type) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final idx = attendances.indexWhere((a) =>
        a.date.year == normalized.year &&
        a.date.month == normalized.month &&
        a.date.day == normalized.day);
    if (idx >= 0) {
      final remaining = attendances[idx].services.where((s) => s != type).toList();
      if (remaining.isEmpty) {
        attendances.removeAt(idx);
      } else {
        attendances[idx].services = remaining;
      }
    }
    streak = attendances.length;
  }

  @override
  Future<List<MassAttendance>> getAttendances() async => List.from(attendances);

  @override
  Future<List<MassAttendance>> getAttendancesByDateRange(
          DateTime start, DateTime end) async =>
      attendances
          .where((a) =>
              (a.date.isAfter(start) || a.date.isAtSameMomentAs(start)) &&
              (a.date.isBefore(end) || a.date.isAtSameMomentAs(end)))
          .toList();

  @override
  Future<int> getStreak() async => streak;

  @override
  Future<int> getBestStreak() async => bestStreak;

  @override
  Future<List<MinistryTask>> getTasks() async => List.from(tasks);

  @override
  Future<void> saveTask(MinistryTask task) async {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      tasks[idx] = task;
    } else {
      tasks.add(task);
    }
  }
}

void main() {
  group('ChurchBloc attendance toggle and streak tests', () {
    late FakeChurchRepository repository;
    late ChurchBloc bloc;

    setUp(() {
      repository = FakeChurchRepository();
      bloc = ChurchBloc(repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('MarkAttendanceEvent adds attendance and updates streak', () async {
      final today = DateTime.now();

      bloc.add(MarkAttendanceEvent(today, ServiceType.liturgy));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChurchState>((state) {
          return state.attendances.length == 1 &&
              state.attendances.first.services.contains(ServiceType.liturgy) &&
              state.currentStreak == 1;
        })),
      );
    });

    test('MarkAttendanceEvent for same day adds new service without duplicating day', () async {
      final today = DateTime.now();

      bloc.add(MarkAttendanceEvent(today, ServiceType.liturgy));
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChurchState>((state) {
          return state.attendances.length == 1;
        })),
      );

      bloc.add(MarkAttendanceEvent(today, ServiceType.vespers));
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChurchState>((state) {
          return state.attendances.length == 1 &&
              state.attendances.first.services.contains(ServiceType.liturgy) &&
              state.attendances.first.services.contains(ServiceType.vespers);
        })),
      );
    });

    test('DeleteAttendanceEvent unmarks specific service', () async {
      final today = DateTime.now();

      // Seed with liturgy and vespers
      await repository.markAttendance(today, ServiceType.liturgy);
      await repository.markAttendance(today, ServiceType.vespers);
      bloc.add(LoadChurchData());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChurchState>((state) {
          return state.status == ChurchStatus.success &&
              state.attendances.first.services.length == 2;
        })),
      );

      // Delete vespers
      bloc.add(DeleteAttendanceEvent(today, ServiceType.vespers));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChurchState>((state) {
          return state.attendances.length == 1 &&
              state.attendances.first.services.contains(ServiceType.liturgy) &&
              !state.attendances.first.services.contains(ServiceType.vespers);
        })),
      );
    });

    test('DeleteAttendanceEvent removes day when last service is deleted', () async {
      final today = DateTime.now();

      await repository.markAttendance(today, ServiceType.liturgy);
      bloc.add(LoadChurchData());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChurchState>((state) =>
            state.status == ChurchStatus.success && state.attendances.length == 1)),
      );

      // Delete the only service
      bloc.add(DeleteAttendanceEvent(today, ServiceType.liturgy));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChurchState>((state) {
          return state.attendances.isEmpty && state.currentStreak == 0;
        })),
      );
    });
  });
}
