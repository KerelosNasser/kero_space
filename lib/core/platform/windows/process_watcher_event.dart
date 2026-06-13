import 'package:equatable/equatable.dart';

abstract class ProcessWatcherEvent extends Equatable {
  const ProcessWatcherEvent();
  @override
  List<Object?> get props => [];
}

class ProcessWatcherStarted extends ProcessWatcherEvent {}

class ProcessTitlePolled extends ProcessWatcherEvent {
  final String title;
  const ProcessTitlePolled(this.title);
  @override
  List<Object?> get props => [title];
}
