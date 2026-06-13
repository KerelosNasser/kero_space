import 'package:equatable/equatable.dart';

abstract class ProcessWatcherState extends Equatable {
  const ProcessWatcherState();
  @override
  List<Object?> get props => [];
}

class ProcessWatcherInitial extends ProcessWatcherState {}

class ProcessChanged extends ProcessWatcherState {
  final String currentTitle;
  const ProcessChanged(this.currentTitle);
  @override
  List<Object?> get props => [currentTitle];
}

class ProcessWatcherUnavailable extends ProcessWatcherState {
  final String reason;
  const ProcessWatcherUnavailable(this.reason);
  @override
  List<Object?> get props => [reason];
}
