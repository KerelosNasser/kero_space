part of 'calendar_bloc.dart';

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState.loading() = _Loading;
  const factory CalendarState.loaded(List<CalendarEvent> events) = _Loaded;
  const factory CalendarState.error(String message) = _Error;
}
