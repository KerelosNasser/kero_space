# Voice Command System — Design Spec
**Date:** 2026-06-13  
**Phase:** 8  
**Status:** Approved (multi-agent review passed)

---

## Overview

An offline-first voice command system that activates even when the device screen is off, transcribes spoken commands via Android's on-device SpeechRecognizer, parses intents using a hybrid (prefix keyword + natural language) engine, and routes actions to the appropriate BLoC (Finance, Health, Church, Telemetry, Productivity, Navigation). All writes require user confirmation before execution.

---

## Decisions Log

| Decision | Chosen | Rationale |
|----------|--------|-----------|
| Transcription engine | `speech_to_text` (Android offline SpeechRecognizer) | Zero NDK complexity, supports partial results, offline on Android 10+. Swap Whisper in V2 once pipeline proven. |
| Rive asset | Source free community `.riv` from rive.app | `rive` package already in pubspec. No manual asset creation needed. |
| Intent domains | All 4 + Navigation + Productivity | Finance, Health, Church, Telemetry, TodoList, Notes, Calendar, Navigation |
| Command triggers | Hybrid: prefix keywords + NL fallback | `todo:`, `note:`, `expense:`, etc. + natural language like "remind me to", "I spent" |
| Confirmation UX | Confirm card before execute + success feedback | Prevents accidental writes from V1 regex parser |
| Global listener | App shell `BlocListener<VoiceBloc>` at root | Clean, zero routing coupling, matches existing architecture |
| Lock screen activation | Native `FLAG_TURN_SCREEN_ON \| FLAG_SHOW_WHEN_LOCKED` from WakeWordService | How Gemini/Assistant do it; proper activity lifecycle; no extra overlay permission |
| BLoC architecture | Monolithic `VoiceBloc` + pure Dart `CommandParser` | Matches existing codebase pattern; testable; simple for V1 |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│               VOICE COMMAND SYSTEM                      │
│                                                         │
│  [WakeWordService — always-on foreground service]        │
│       │  wake word detected (AudioRecord → ONNX stub)   │
│       ▼                                                 │
│  startActivity(                                         │
│    FLAG_TURN_SCREEN_ON,    ← wakes display              │
│    FLAG_SHOW_WHEN_LOCKED,  ← renders over keyguard      │
│    FLAG_ACTIVITY_NEW_TASK                               │
│  )                                                      │
│       │                                                 │
│       ▼                                                 │
│  kero_space/wake_word EventChannel                      │
│       │                                                 │
│       ▼                                                 │
│  VoiceBloc (state machine)                              │
│  ┌────────────────────────────────┐                     │
│  │  Idle                          │                     │
│  │  → WakeWordDetected            │                     │
│  │  → Listening (partial text)    │                     │
│  │  → Processing                  │                     │
│  │  → ConfirmPending (ParsedIntent│                     │
│  │  → Success                     │                     │
│  │  → Failure                     │                     │
│  └────────────────────────────────┘                     │
│       │                                                 │
│       ▼                                                 │
│  CommandParser (pure Dart, no Flutter deps)             │
│  ┌────────────────────────────────┐                     │
│  │  1. Normalize transcript        │                     │
│  │     (number words, trigger      │                     │
│  │      variants, filler removal)  │                     │
│  │  2. Try prefix-trigger match    │                     │
│  │  3. Fallback: NL regex match    │                     │
│  │  4. Return ParsedIntent         │                     │
│  └────────────────────────────────┘                     │
│       │                                                 │
│       ▼                                                 │
│  Intent Router (inside VoiceBloc)                       │
│  Finance / Health / Church / Telemetry /                │
│  Productivity / Navigation                              │
│                                                         │
│  UI: VoiceBottomSheet                                   │
│    - DraggableScrollableSheet (initialSize: 0.35)       │
│    - Rive waveform animation                            │
│    - Live partial transcription text                    │
│    - Cycling command hint ticker (discoverability)      │
│    - Confirm card with Yes/No buttons                   │
│    - Success toast (auto-dismiss 1.5s)                  │
│    - Failure card with contextual examples              │
└─────────────────────────────────────────────────────────┘
```

---

## State Machine

```
Idle
 └─► WakeWordDetected  (on kero_space/wake_word event)
      └─► Listening     (speech_to_text.startListening, onDevice: true)
           │             [5s hard timeout → back to Idle]
           │             [partial results → update Listening.partialText]
           └─► Processing (final transcript received)
                └─► ConfirmPending(ParsedIntent)   (known intent)
                │    ├─► Success   (user confirms → BLoC dispatch)
                │    └─► Idle      (user cancels)
                └─► Failure(UnknownIntent)          (unknown intent)
                     └─► Idle (dismiss or retry)
```

---

## CommandParser — Intent Map

| Domain | Prefix Triggers | NL Patterns | Extracted Entities |
|--------|----------------|-------------|-------------------|
| Productivity — Todo | `todo:` `task:` | "add task", "remind me to" | title, recurrence (daily/weekly/every X) |
| Productivity — Note | `note:` | "take a note", "write down", "jot down" | body text |
| Productivity — Event | `event:` `schedule:` | "add event", "schedule", "put on calendar" | title, date, time |
| Finance — Expense | `expense:` `spent:` | "I spent", "add expense", "paid" | amount (EGP), vendor/category |
| Finance — Income | `income:` | "I received", "add income", "got paid" | amount, source |
| Health — Meal | `meal:` `log:` `ate:` | "log meal", "I ate", "I had" | food name, grams (optional) |
| Church | — | "mark attendance", "I went to mass", "attended church" | date (defaults today) |
| Telemetry | — | "block [app]", "unblock [app]", "blacklist [app]" | app name |
| Navigation | — | "open [feature]", "show [feature]", "go to [feature]" | feature name |

### Normalization Pre-processor
Before any regex matching:
1. Number words → digits: "fifty" → "50", "two hundred" → "200"
2. Trigger variants: "to do", "to-do", "todos" → "todo"
3. Filler removal: "um", "uh", "like", "you know" stripped
4. Lowercase entire transcript

### Recurrence Extraction
```
"todo: shower daily"             → { title: "shower", recurrence: Recurrence.daily }
"todo: call mom every week"      → { title: "call mom", recurrence: Recurrence.weekly }
"remind me to pray every morning"→ { title: "pray", recurrence: Recurrence.daily, hint: "morning" }
```

---

## ParsedIntent Sealed Class Hierarchy

```dart
sealed class ParsedIntent { const ParsedIntent(); }

class AddTodoIntent    extends ParsedIntent { final String title; final Recurrence? recurrence; }
class AddNoteIntent    extends ParsedIntent { final String body; }
class AddEventIntent   extends ParsedIntent { final String title; final DateTime? dateTime; }
class AddExpenseIntent extends ParsedIntent { final double amount; final String? vendor; }
class AddIncomeIntent  extends ParsedIntent { final double amount; final String? source; }
class LogMealIntent    extends ParsedIntent { final String food; final int? grams; }
class MarkAttendanceIntent extends ParsedIntent { final DateTime date; }
class BlockAppIntent   extends ParsedIntent { final String appName; }
class NavigateIntent   extends ParsedIntent { final String destination; }
class UnknownIntent    extends ParsedIntent { final String raw; }
```

---

## Native Android Changes

### AndroidManifest.xml
```xml
<activity
  android:name=".MainActivity"
  android:turnScreenOn="true"
  android:showWhenLocked="true"
  ...
/>
```

### MainActivity.kt
```kotlin
override fun onCreate(...) {
  super.onCreate(...)
  setShowWhenLocked(true)
  setTurnScreenOn(true)
}
override fun onNewIntent(intent: Intent) {
  super.onNewIntent(intent)
  setShowWhenLocked(true)
  setTurnScreenOn(true)
}
```

### WakeWordService.kt — lock screen launch
```kotlin
private fun launchMainActivity() {
  val intent = Intent(this, MainActivity::class.java).apply {
    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
             Intent.FLAG_ACTIVITY_SINGLE_TOP)
    putExtra("VOICE_WAKE_TRIGGERED", true)
  }
  startActivity(intent)
  // 600ms buffer before Flutter engine ready
  Handler(Looper.getMainLooper()).postDelayed({
    wakeWordEventSink?.success(/* json event */)
  }, 600)
}
```

---

## VoiceBottomSheet UI States

### Listening state
```
┌─────────────────────────────────┐
│  [Rive waveform — active bars]  │
│  "todo: shower daily_"          │  ← live partial text
│  ──────────────────────────     │
│  💡 try: "note: [your note]"    │  ← cycling hint ticker
└─────────────────────────────────┘
```

### ConfirmPending state
```
┌─────────────────────────────────┐
│  ✅  Add Todo                   │
│      "Shower"  •  Daily         │
│                                 │
│  [  ✓ Confirm  ]  [  ✗ Cancel ]│
└─────────────────────────────────┘
```

### Success state (auto-dismiss 1.5s)
```
┌─────────────────────────────────┐
│  [Rive success burst animation] │
│  "Done! Todo added ✓"           │
└─────────────────────────────────┘
```

### Failure state (UnknownIntent)
```
┌─────────────────────────────────┐
│  ⚠️  "I didn't understand that" │
│  Try: "todo: shower daily"      │
│       "expense: 200 groceries"  │
│  [ Try Again ]  [ Dismiss ]     │
└─────────────────────────────────┘
```

---

## Constraints & Risk Mitigations

| Risk | Mitigation |
|------|-----------|
| OEM lock screen blocks SpeechRecognizer | 300ms delay before startListening; known limitation documented |
| Engine warm-up gap eats first word | 600ms buffer in WakeWordService before emitting event; animation covers wait |
| Mic runaway / battery drain | 5s hard timeout Timer in VoiceBloc; stops on StopListeningEvent |
| Raw transcript privacy | Discarded immediately after CommandParser returns; never written to Isar |
| Offline SpeechRecognizer unavailable | `onDevice: true` check; emit VoiceFailure with actionable message |
| Regex brittle against ASR errors | Normalization pre-processor handles number words, trigger variants, fillers |
| Bottom sheet covers screen | DraggableScrollableSheet initialChildSize: 0.35; scrim opacity 0.3 |
| No discoverability | Cycling hint ticker in Listening state shows 3 example commands |

---

## File Structure

```
lib/features/voice/
  domain/
    command_parser.dart         ← pure Dart, no Flutter
    parsed_intent.dart          ← sealed class hierarchy
    recurrence.dart             ← enum: daily, weekly, monthly, none
  presentation/
    bloc/
      voice_bloc.dart
      voice_event.dart
      voice_state.dart
    widgets/
      voice_bottom_sheet.dart
      confirm_intent_card.dart
      command_hint_ticker.dart
      voice_waveform.dart       ← Rive asset wrapper

android/app/src/main/
  AndroidManifest.xml           ← turnScreenOn + showWhenLocked
  kotlin/.../
    MainActivity.kt             ← setShowWhenLocked + setTurnScreenOn
    WakeWordService.kt          ← launchMainActivity() with flags + 600ms delay

assets/animations/
  voice_wave.riv                ← sourced from rive.app/community

test/features/voice/
  domain/
    command_parser_test.dart    ← 30+ phrase variations per intent
  presentation/
    bloc/
      voice_bloc_test.dart      ← full state machine transitions
```

---

## Definition of Done

- Wake word (ADB mock: `adb shell am broadcast -a com.example.kero_space.WAKE_WORD_TRIGGER`) wakes the screen, opens `VoiceBottomSheet`
- `speech_to_text` streams partial results live in the bottom sheet
- All 9 intent domains parse correctly in unit tests with 30+ phrase variations
- Confirm card appears for every write intent; action executes only on confirm
- Success feedback shown and sheet auto-dismisses in 1.5s
- `flutter analyze` passes clean
- `flutter build apk --debug` succeeds
