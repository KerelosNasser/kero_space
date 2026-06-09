import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/models/productivity_collections.dart';
import '../../data/repositories/local_calendar_repository.dart';

part 'calendar_bloc.freezed.dart';
part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEventBlocEvent, CalendarState> {
  final LocalCalendarRepository repository;

  CalendarBloc(this.repository) : super(const CalendarState.loading()) {
    on<LoadCalendarEvents>(_onLoadEvents);
  }

  Future<void> _onLoadEvents(LoadCalendarEvents event, Emitter<CalendarState> emit) async {
    emit(const CalendarState.loading());
    try {
      final events = await repository.getLocalEvents();
      // Sort chronologically
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      emit(CalendarState.loaded(events));
    } catch (e) {
      emit(CalendarState.error(e.toString()));
    }
  }
}
