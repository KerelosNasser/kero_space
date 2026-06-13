# Voice Command System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the offline-first Voice Command System using Android's native SpeechRecognizer and a pure Dart CommandParser.
**Architecture:** Monolithic VoiceBloc + pure Dart CommandParser, triggered via Android lock-screen capable foreground service.
**Tech Stack:** `speech_to_text`, `rive`, Bloc, Android Intents.

---

### Task 1: Native Setup & Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/example/kero_space/MainActivity.kt`
- Modify: `android/app/src/main/kotlin/com/example/kero_space/WakeWordService.kt`

- [ ] **Step 1: Add dependencies**
  - Add `speech_to_text: ^6.6.1` to `pubspec.yaml`.
- [ ] **Step 2: Update AndroidManifest**
  - Add `android:turnScreenOn="true"` and `android:showWhenLocked="true"` to `.MainActivity`.
- [ ] **Step 3: Update MainActivity.kt**
  - Override `onCreate` and `onNewIntent` to call `setShowWhenLocked(true)` and `setTurnScreenOn(true)`.
- [ ] **Step 4: Update WakeWordService.kt**
  - Update `mockTriggerReceiver` to launch `MainActivity` with `FLAG_ACTIVITY_NEW_TASK` and `FLAG_ACTIVITY_SINGLE_TOP`.
  - Delay 600ms, then emit the wake word event to `wakeWordEventSink`.
- [ ] **Step 5: Run flutter pub get & commit**

### Task 2: Domain Layer (ParsedIntent & CommandParser)

**Files:**
- Create: `lib/features/voice/domain/parsed_intent.dart`
- Create: `lib/features/voice/domain/recurrence.dart`
- Create: `lib/features/voice/domain/command_parser.dart`
- Create: `test/features/voice/domain/command_parser_test.dart`

- [ ] **Step 1: Create Enums & Sealed Class**
  - Define `Recurrence` enum.
  - Define `ParsedIntent` sealed class and subclasses.
- [ ] **Step 2: Write CommandParser tests**
  - Write test cases for 9 domains + normalization.
- [ ] **Step 3: Implement CommandParser**
  - Implement normalization, prefix regexes, and NL fallbacks.
- [ ] **Step 4: Verify tests & commit**

### Task 3: Presentation Layer (VoiceBloc)

**Files:**
- Create: `lib/features/voice/presentation/bloc/voice_event.dart`
- Create: `lib/features/voice/presentation/bloc/voice_state.dart`
- Create: `lib/features/voice/presentation/bloc/voice_bloc.dart`

- [ ] **Step 1: Define Events & States**
  - Idle, WakeWordDetected, Listening, Processing, ConfirmPending, Success, Failure.
- [ ] **Step 2: Implement VoiceBloc**
  - Listen to `kero_space/wake_word` channel.
  - Integrate `speech_to_text` (with `onDevice: true` constraint).
  - Manage the 5s hard timeout.
  - Delegate to `CommandParser`.
- [ ] **Step 3: Wire into getIt**
  - Register `VoiceBloc` as singleton in `lib/core/di/injection.dart`.
- [ ] **Step 4: Commit**

### Task 4: UI Layer (VoiceBottomSheet & Global Listener)

**Files:**
- Create: `lib/features/voice/presentation/widgets/voice_waveform.dart`
- Create: `lib/features/voice/presentation/widgets/command_hint_ticker.dart`
- Create: `lib/features/voice/presentation/widgets/voice_bottom_sheet.dart`
- Modify: `lib/core/router.dart` (or `main.dart` / app shell)

- [ ] **Step 1: Rive & Ticker Widgets**
  - Placeholder Rive animation (or fallback painter).
  - Cycling hints text.
- [ ] **Step 2: Bottom Sheet UI**
  - DraggableScrollableSheet reacting to VoiceState.
- [ ] **Step 3: Global Integration**
  - Add `BlocListener<VoiceBloc>` to the app root to trigger the sheet.
- [ ] **Step 4: Verify UI & commit**
