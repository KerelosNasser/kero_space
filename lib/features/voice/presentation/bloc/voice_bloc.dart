import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/command_parser.dart';
import '../../domain/parsed_intent.dart';
import 'voice_event.dart';
import 'voice_state.dart';

// Domain BLoCs and Models
import 'package:kero_space/features/productivity/presentation/bloc/productivity_bloc.dart';
import 'package:kero_space/features/productivity/data/models/productivity_collections.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';
import 'package:kero_space/features/church/data/models/mass_attendance.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final CommandParser _parser;
  final ProductivityBloc _productivityBloc;
  final HealthBloc _healthBloc;
  final FinanceBloc _financeBloc;
  final ChurchBloc _churchBloc;

  final SpeechToText _speech = SpeechToText();
  
  static const EventChannel _wakeWordChannel = EventChannel('kero_space/wake_word');
  StreamSubscription? _wakeWordSubscription;
  Timer? _listenTimeout;

  VoiceBloc(
    this._parser,
    this._productivityBloc,
    this._healthBloc,
    this._financeBloc,
    this._churchBloc,
  ) : super(VoiceIdle()) {
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
      add(WakeWordTriggered());
    });
  }

  Future<void> _onWakeWordTriggered(WakeWordTriggered event, Emitter<VoiceState> emit) async {
    emit(VoiceWakeDetected());
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
      String msg = "Done!";

      if (intent is AddTodoIntent) {
        msg = "Added to do";
        final task = Task()
          ..title = intent.title
          ..type = TaskType.task
          ..deviceId = 'voice'
          ..platform = 'voice'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        _productivityBloc.add(ProductivityEvent.createTask(task));
      } else if (intent is AddNoteIntent) {
        msg = "Note saved";
        final note = Note()
          ..title = "Voice Note"
          ..quillDelta = '[{"insert":"${intent.body}\\n"}]'
          ..deviceId = 'voice'
          ..platform = 'voice'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        _productivityBloc.add(ProductivityEvent.createNote(note));
      } else if (intent is AddExpenseIntent) {
        msg = "Expense recorded";
        _financeBloc.add(AddTransactionEvent(
          amount: intent.amount,
          type: 'EXPENSE',
          category: 'Other',
          vendor: intent.vendor ?? 'Voice',
        ));
      } else if (intent is LogMealIntent) {
        msg = "Meal logged";
        final meal = MealEntry()
          ..name = intent.food
          ..grams = (intent.grams ?? 100).toDouble()
          ..calories = 0
          ..protein = 0
          ..carbs = 0
          ..fat = 0
          ..deviceId = 'voice'
          ..platform = 'voice'
          ..timestamp = DateTime.now();
        _healthBloc.add(LogMeal(meal));
      } else if (intent is MarkAttendanceIntent) {
        msg = "Attendance marked";
        _churchBloc.add(MarkAttendanceEvent(intent.date, AttendanceType.liturgy));
      }
      
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
