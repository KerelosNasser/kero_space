import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/productivity_collections.dart';
import '../../data/repositories/local_calendar_repository.dart';
import '../../../../core/utils/coptic_computus.dart';

part 'calendar_bloc.freezed.dart';
part 'calendar_event.dart';
part 'calendar_state.dart';

List<Map<String, dynamic>> _computeCopticEvents(List<int> yearRange) {
  final results = <Map<String, dynamic>>[];
  final startYear = yearRange[0];
  final endYear = yearRange[1];

  for (int year = startYear; year <= endYear; year++) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);

    for (int i = 0; i <= endOfYear.difference(startOfYear).inDays; i++) {
      final currentDate = startOfYear.add(Duration(days: i));
      final fastType = CopticComputus.getFastType(currentDate);

      if (fastType != FastType.none) {
        results.add({
          'title': _getFastNameStatic(fastType),
          'startTime': currentDate.millisecondsSinceEpoch,
          'year': year,
          'month': currentDate.month,
          'day': currentDate.day,
        });
      }
    }
  }
  return results;
}

String _getFastNameStatic(FastType type) {
  switch (type) {
    case FastType.greatLent:
      return "Great Lent";
    case FastType.jonahsFast:
      return "Jonah's Fast";
    case FastType.apostlesFast:
      return "Apostles' Fast";
    case FastType.adventFast:
      return "Nativity Fast (Advent)";
    case FastType.wednesdayFriday:
      return "Wednesday/Friday Fast";
    case FastType.paramoun:
      return "Paramoun Fast";
    default:
      return "";
  }
}

class CalendarBloc extends Bloc<CalendarEventBlocEvent, CalendarState> {
  final LocalCalendarRepository repository;

  CalendarBloc(this.repository) : super(const CalendarState.loading()) {
    on<LoadCalendarEvents>(_onLoadEvents);
  }

  Future<void> _onLoadEvents(LoadCalendarEvents event, Emitter<CalendarState> emit) async {
    emit(const CalendarState.loading());
    try {
      final events = await repository.getLocalEvents();

      final now = DateTime.now();
      final copticResults = await compute(_computeCopticEvents, [now.year - 1, now.year + 1]);

      final copticEvents = copticResults.map((r) {
        final startTime = DateTime(r['year'] as int, r['month'] as int, r['day'] as int);
        return CalendarEvent()
          ..deviceId = 'coptic_computus'
          ..platform = 'dart'
          ..title = r['title'] as String
          ..startTime = startTime
          ..endTime = startTime.add(const Duration(days: 1))
          ..source = 'COPTIC'
          ..allDay = true;
      }).toList();

      final merged = [...events, ...copticEvents];
      merged.sort((a, b) => a.startTime.compareTo(b.startTime));
      emit(CalendarState.loaded(merged));
    } catch (e) {
      emit(const CalendarState.error('Failed to load calendar events.'));
    }
  }
}
