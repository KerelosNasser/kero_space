import 'package:equatable/equatable.dart';

sealed class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => [];
}

class WakeWordTriggered extends VoiceEvent {}

class StartListeningEvent extends VoiceEvent {}

class StopListeningEvent extends VoiceEvent {}

class SpeechPartialResultEvent extends VoiceEvent {
  final String text;

  const SpeechPartialResultEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class SpeechFinalResultEvent extends VoiceEvent {
  final String text;

  const SpeechFinalResultEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ConfirmIntentEvent extends VoiceEvent {}

class CancelIntentEvent extends VoiceEvent {}
