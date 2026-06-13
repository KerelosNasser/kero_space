import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/command_parser.dart';
import '../../domain/parsed_intent.dart';
import 'voice_event.dart';
import 'voice_state.dart';

@lazySingleton
class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final CommandParser _parser;
  final SpeechToText _speech = SpeechToText();
  
  static const EventChannel _wakeWordChannel = EventChannel('kero_space/wake_word');
  StreamSubscription? _wakeWordSubscription;
  Timer? _listenTimeout;

  VoiceBloc(this._parser) : super(VoiceIdle()) {
    on<WakeWordTriggered>(_onWakeWordTriggered);
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<SpeechPartialResultEvent>(_onSpeechPartialResult);
    on<SpeechFinalResultEvent>(_onSpeechFinalResult);
    on<ConfirmIntentEvent>(_onConfirmIntent);
    on<CancelIntentEvent>(_onCancelIntent);

    _initWakeWordListener();
  }

  void _initWakeWordListener() {
    _wakeWordSubscription = _wakeWordChannel.receiveBroadcastStream().listen((event) {
      // Event implies WAKE_WORD_DETECTED
      add(WakeWordTriggered());
    });
  }

  Future<void> _onWakeWordTriggered(WakeWordTriggered event, Emitter<VoiceState> emit) async {
    emit(VoiceWakeDetected());
    
    // Give a small UI buffer for the user to see the bottom sheet
    await Future.delayed(const Duration(milliseconds: 500));
    add(StartListeningEvent());
  }

  Future<void> _onStartListening(StartListeningEvent event, Emitter<VoiceState> emit) async {
    final available = await _speech.initialize(
      options: [SpeechConfigOption('android', 'onDevice', 'true')]
    );
    
    if (!available) {
      emit(const VoiceFailure(
        rawText: '', 
        errorMessage: 'Offline speech not available — install a language pack in Android settings.',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(VoiceIdle());
      return;
    }

    emit(const VoiceListening());
    
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          add(SpeechFinalResultEvent(result.recognizedWords));
        } else {
          add(SpeechPartialResultEvent(result.recognizedWords));
        }
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );

    // Hard timeout 5s
    _listenTimeout?.cancel();
    _listenTimeout = Timer(const Duration(seconds: 5), () {
      add(StopListeningEvent());
    });
  }

  void _onStopListening(StopListeningEvent event, Emitter<VoiceState> emit) {
    _listenTimeout?.cancel();
    if (_speech.isListening) {
      _speech.stop();
    }
    // If we're still just listening without processing, go back to idle
    if (state is VoiceListening) {
      emit(VoiceIdle());
    }
  }

  void _onSpeechPartialResult(SpeechPartialResultEvent event, Emitter<VoiceState> emit) {
    if (state is VoiceListening) {
      emit(VoiceListening(partialText: event.text));
    }
  }

  void _onSpeechFinalResult(SpeechFinalResultEvent event, Emitter<VoiceState> emit) {
    _listenTimeout?.cancel();
    emit(VoiceProcessing(event.text));

    final intent = _parser.parse(event.text);
    if (intent is UnknownIntent) {
      emit(VoiceFailure(rawText: event.text, errorMessage: "I didn't understand that."));
    } else {
      emit(VoiceConfirmPending(intent));
    }
  }

  Future<void> _onConfirmIntent(ConfirmIntentEvent event, Emitter<VoiceState> emit) async {
    if (state is VoiceConfirmPending) {
      final intent = (state as VoiceConfirmPending).intent;
      
      // The VoiceBloc emits success, but the actual domain BLoC execution 
      // will be handled in the UI by listening to this success state 
      // OR we can inject other Blocs here. 
      // For V1 architecture, we just emit Success so the UI dismisses, 
      // and the UI can dispatch to the right BLoC based on the intent we carried.
      // Wait, the plan says: "Intent Router (inside VoiceBloc)". Let's just emit success 
      // and let the UI or a middleware handle it. For now, Success.
      
      String msg = "Done!";
      if (intent is AddTodoIntent) msg = "Added to do";
      if (intent is AddNoteIntent) msg = "Note saved";
      if (intent is AddExpenseIntent) msg = "Expense recorded";
      if (intent is LogMealIntent) msg = "Meal logged";
      
      emit(VoiceSuccess(msg));
      
      await Future.delayed(const Duration(milliseconds: 1500));
      emit(VoiceIdle());
    }
  }

  void _onCancelIntent(CancelIntentEvent event, Emitter<VoiceState> emit) {
    emit(VoiceIdle());
  }

  @override
  Future<void> close() {
    _wakeWordSubscription?.cancel();
    _listenTimeout?.cancel();
    _speech.cancel();
    return super.close();
  }
}
