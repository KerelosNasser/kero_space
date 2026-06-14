import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/productivity_collections.dart';
import '../../data/repositories/local_calendar_repository.dart';
import '../../../../core/utils/coptic_computus.dart';

part 'calendar_bloc.freezed.dart';
part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEventBlocEvent, CalendarState> {
  final LocalCalendarRepository repository;
  List<CalendarEvent>? _cachedCopticEvents;

  CalendarBloc(this.repository) : super(const CalendarState.loading()) {
    on<LoadCalendarEvents>(_onLoadEvents);
  }

  Future<void> _onLoadEvents(LoadCalendarEvents event, Emitter<CalendarState> emit) async {
    emit(const CalendarState.loading());
    try {
      final events = await repository.getLocalEvents();
      
      if (_cachedCopticEvents == null) {
        _cachedCopticEvents = [];
        final now = DateTime.now();
        for (int year = now.year - 1; year <= now.year + 1; year++) {
          final startOfYear = DateTime(year, 1, 1);
          final endOfYear = DateTime(year, 12, 31);
          
          for (int i = 0; i <= endOfYear.difference(startOfYear).inDays; i++) {
            final currentDate = startOfYear.add(Duration(days: i));
            final fastType = CopticComputus.getFastType(currentDate);
            
            if (fastType != FastType.none) {
              _cachedCopticEvents!.add(
                CalendarEvent()
                  ..deviceId = 'coptic_computus'
                  ..platform = 'dart'
                  ..title = _getFastName(fastType)
                  ..startTime = currentDate
                  ..endTime = currentDate.add(const Duration(days: 1))
                  ..source = 'COPTIC'
                  ..allDay = true,
              );
            }
          }
        }
      }

      events.addAll(_cachedCopticEvents!);

      // Sort chronologically
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      emit(CalendarState.loaded(events));
    } catch (e) {
      emit(CalendarState.error(e.toString()));
    }
  }

  String _getFastName(FastType type) {
    switch (type) {
      case FastType.greatLent: return "Great Lent";
      case FastType.jonahsFast: return "Jonah's Fast";
      case FastType.apostlesFast: return "Apostles' Fast";
      case FastType.adventFast: return "Nativity Fast (Advent)";
      case FastType.wednesdayFriday: return "Wednesday/Friday Fast";
      case FastType.paramoun: return "Paramoun Fast";
      default: return "";
    }
  }
}
