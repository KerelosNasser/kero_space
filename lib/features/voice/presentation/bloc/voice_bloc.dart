import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/command_parser.dart';
import '../../domain/parsed_intent.dart';
import 'voice_event.dart';
import 'voice_state.dart';

import 'package:kero_space/core/di/injection.dart';
import 'package:kero_space/core/data/kero_space_platform_service.dart';
import 'package:kero_space/features/productivity/presentation/bloc/productivity_bloc.dart';
import 'package:kero_space/features/productivity/data/models/productivity_collections.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';
import 'package:kero_space/features/church/data/models/mass_attendance.dart';
import 'package:kero_space/features/telemetry/data/models/blacklist_rule.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final CommandParser _parser;

  static const EventChannel _wakeWordChannel = EventChannel(
    'kero_space/wake_word',
  );
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
    _wakeWordSubscription = _wakeWordChannel.receiveBroadcastStream().listen((
      event,
    ) {
      if (event is String) {
        try {
          final data = jsonDecode(event);
          if (data['type'] == 'WAKE_WORD_DETECTED') {
            add(WakeWordTriggered());
          } else if (data['type'] == 'TRANSCRIPTION_COMPLETE') {
            add(SpeechFinalResultEvent(data['text']));
          } else if (data['type'] == 'TRANSCRIPTION_PARTIAL') {
            add(SpeechPartialResultEvent(data['text']));
          }
        } catch (_) {
          // Malformed data from native channel — don't trigger wake word
        }
      }
    });
  }

  Future<void> _onWakeWordTriggered(
    WakeWordTriggered event,
    Emitter<VoiceState> emit,
  ) async {
    emit(VoiceWakeDetected());
    await Future.delayed(const Duration(milliseconds: 500));
    add(StartListeningEvent());
  }

  Future<void> _onStartListening(
    StartListeningEvent event,
    Emitter<VoiceState> emit,
  ) async {
    // Native WakeWordService has transitioned to CommandCapture mode
    // and is already recording the microphone.
    emit(const VoiceListening());

    _listenTimeout?.cancel();
    _listenTimeout = Timer(const Duration(seconds: 5), () {
      add(StopListeningEvent());
    });
  }

  void _onStopListening(StopListeningEvent event, Emitter<VoiceState> emit) {
    _listenTimeout?.cancel();
    if (state is VoiceListening) {
      emit(VoiceIdle());
    }
  }

  void _onSpeechPartialResult(
    SpeechPartialResultEvent event,
    Emitter<VoiceState> emit,
  ) {
    if (state is VoiceListening) {
      emit(VoiceListening(partialText: event.text));
    }
  }

  void _onSpeechFinalResult(
    SpeechFinalResultEvent event,
    Emitter<VoiceState> emit,
  ) {
    _listenTimeout?.cancel();
    emit(VoiceProcessing(event.text));

    final intent = _parser.parse(event.text);
    if (intent is UnknownIntent) {
      emit(
        VoiceFailure(
          rawText: event.text,
          errorMessage: "I didn't understand that.",
        ),
      );
    } else {
      emit(VoiceConfirmPending(intent));
    }
  }

  Future<void> _onConfirmIntent(
    ConfirmIntentEvent event,
    Emitter<VoiceState> emit,
  ) async {
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
        getIt<ProductivityBloc>().add(ProductivityEvent.createTask(task));
      } else if (intent is AddNoteIntent) {
        msg = "Note saved";
        final note = Note()
          ..title = "Voice Note"
          ..quillDelta = '[{"insert":"${intent.body}\\n"}]'
          ..deviceId = 'voice'
          ..platform = 'voice'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        getIt<ProductivityBloc>().add(ProductivityEvent.createNote(note));
      } else if (intent is AddEventIntent) {
        msg = "Event added";
        final task = Task()
          ..title = intent.title
          ..type = TaskType.task
          ..deviceId = 'voice'
          ..platform = 'voice'
          ..dueDate = intent.dateTime
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        getIt<ProductivityBloc>().add(ProductivityEvent.createTask(task));
      } else if (intent is AddExpenseIntent) {
        msg = "Expense recorded";
        getIt<FinanceBloc>().add(
          AddTransactionEvent(
            amount: intent.amount,
            type: 'EXPENSE',
            category: 'Other',
            vendor: intent.vendor ?? 'Voice',
          ),
        );
      } else if (intent is AddIncomeIntent) {
        msg = "Income recorded";
        getIt<FinanceBloc>().add(
          AddTransactionEvent(
            amount: intent.amount,
            type: 'INCOME',
            category: 'Income',
            vendor: intent.source ?? 'Voice',
          ),
        );
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
        getIt<HealthBloc>().add(LogMeal(meal));
      } else if (intent is MarkAttendanceIntent) {
        msg = "Attendance marked";
        getIt<ChurchBloc>().add(
          MarkAttendanceEvent(intent.date, AttendanceType.liturgy),
        );
      } else if (intent is NavigateIntent) {
        // Navigation is handled by the UI layer listening to state changes
        msg = 'Opening ${intent.destination}';
      } else if (intent is BlockAppIntent) {
        msg = 'App blocked';
        final rule = BlacklistRule(packageName: intent.appName);
        final rulesJson = BlacklistRule.listToJson([rule]);
        await getIt<KeroSpacePlatformService>().setBlacklistRules(rulesJson);
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
    return super.close();
  }
}
