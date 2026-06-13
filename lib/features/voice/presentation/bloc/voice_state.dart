import 'package:equatable/equatable.dart';
import '../../domain/parsed_intent.dart';

sealed class VoiceState extends Equatable {
  const VoiceState();

  @override
  List<Object?> get props => [];
}

class VoiceIdle extends VoiceState {}

class VoiceWakeDetected extends VoiceState {}

class VoiceListening extends VoiceState {
  final String partialText;

  const VoiceListening({this.partialText = ''});

  @override
  List<Object?> get props => [partialText];
}

class VoiceProcessing extends VoiceState {
  final String text;

  const VoiceProcessing(this.text);

  @override
  List<Object?> get props => [text];
}

class VoiceConfirmPending extends VoiceState {
  final ParsedIntent intent;

  const VoiceConfirmPending(this.intent);

  @override
  List<Object?> get props => [intent];
}

class VoiceSuccess extends VoiceState {
  final String message;

  const VoiceSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class VoiceFailure extends VoiceState {
  final String rawText;
  final String errorMessage;

  const VoiceFailure({required this.rawText, required this.errorMessage});

  @override
  List<Object?> get props => [rawText, errorMessage];
}
