part of 'calendar_bloc.dart';

@freezed
class CalendarEventBlocEvent with _$CalendarEventBlocEvent {
  const factory CalendarEventBlocEvent.loadEvents() = LoadCalendarEvents;
}
