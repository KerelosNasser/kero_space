# agents.md — Background Agent Specification

## Overview

The "Omniscient Layer" is powered by four persistent background agents, each operating as an independent Android Service or system-level component. These agents are the sensory nervous system of Kero Space — they observe, classify, and pipe behavioral data into the Isar cache continuously, regardless of whether the Flutter UI is active.

All agents are architecturally **push-based**: they emit events into named platform channels, which the Flutter EventChannel listeners receive and forward to the relevant BLoC.

```
┌─────────────────────────────────────────────────────────────────┐
│                    AGENT ARCHITECTURE                           │
│                                                                 │
│  Agent 1: AccessibilityAgent  ──→  kero_space/accessibility     │
│  Agent 2: UsageGuardAgent     ──→  kero_space/usage_stats       │
│  Agent 3: ScreenEventAgent    ──→  kero_space/screen_events     │
│  Agent 4: WakeWordAgent       ──→  kero_space/wake_word         │
│                                                                 │
│  All agents bound to KeroSpaceForegroundService (persistent)    │
│  Foreground notification: minimal, non-dismissible              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Agent 1: AccessibilityAgent

### What It Does
The `AccessibilityAgent` is an `AccessibilityService` implementation that monitors UI interactions system-wide. It is the engine behind both the **Mindless Scrolling Blocker** and the **System-Wide Click Logger**.

### Android Component
```
Class: KeroSpaceAccessibilityService extends AccessibilityService
Declaration: AndroidManifest.xml
  android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
  <meta-data android:name="android.accessibilityservice"
             android:resource="@xml/accessibility_service_config"/>
```

### Accessibility Service Config
```xml
<accessibility-service
  android:accessibilityEventTypes="typeWindowStateChanged|typeViewClicked|typeViewTextChanged"
  android:accessibilityFeedbackType="feedbackGeneric"
  android:notificationTimeout="100"
  android:accessibilityFlags="flagDefault|flagReportViewIds|flagRequestFilterKeyEvents"
  android:canRetrieveWindowContent="true"/>
```

### Functional Flow: Mindless Scrolling Blocker

```
┌────────────────────────────────────────────────────────────┐
│  SCROLLING BLOCKER DECISION TREE                           │
│                                                            │
│  onAccessibilityEvent(TYPE_WINDOW_STATE_CHANGED)           │
│      │                                                     │
│      ▼                                                     │
│  Extract packageName from event.packageName                │
│      │                                                     │
│      ▼                                                     │
│  Is packageName in BlacklistRepository?                    │
│      │ NO → log event, return                              │
│      │ YES ↓                                               │
│      ▼                                                     │
│  Is current time in user's "allowed window"?               │
│      │ YES → allow, log as "granted" event                 │
│      │ NO  ↓                                               │
│      ▼                                                     │
│  Has DecisionBreak already been served for this session?   │
│      │ YES → allow (break already taken)                   │
│      │ NO  ↓                                               │
│      ▼                                                     │
│  OverlayManager.show(packageName, configuredDuration)      │
│      → Launches TYPE_APPLICATION_OVERLAY window            │
│      → Decision break timer starts                         │
│      → App remains underneath but interaction blocked       │
│                                                            │
│  On timer expiry:                                          │
│  OverlayManager.dismiss()                                  │
│  DecisionBreakLog.record(packageName, timestamp, outcome)  │
└────────────────────────────────────────────────────────────┘
```

### Overlay Window Implementation
The overlay is a `WindowManager`-managed `View` added with:
```
LayoutParams.TYPE_APPLICATION_OVERLAY
LayoutParams.FLAG_NOT_FOCUSABLE (during countdown)
LayoutParams.FLAG_LAYOUT_IN_SCREEN
```
The overlay renders the Rive animation countdown, package icon, and configurable message. On Android 12+, the overlay self-dismisses and logs the result when the timer expires. The user may also **override** via a deliberately difficult gesture (e.g., long-press + swipe) — all overrides are logged.

### Functional Flow: Click Logger

Every `TYPE_VIEW_CLICKED` and `TYPE_VIEW_TEXT_CHANGED` event is processed:

```
onAccessibilityEvent(event) {
  val record = ClickRecord(
    timestamp    = System.currentTimeMillis(),
    packageName  = event.packageName,
    className    = event.className,
    viewId       = event.source?.viewIdResourceName,
    text         = sanitize(event.text),  // strips PII patterns (passwords, card #)
    clickX       = event.source?.getBoundsInScreen().centerX(),
    clickY       = event.source?.getBoundsInScreen().centerY(),
  )
  EventChannel.sink.add(record.toJson())
}
```

**PII Sanitization:** Before logging, the `sanitize()` function:
1. Redacts strings matching password field patterns (view ID contains "password", "pin", "secret")
2. Redacts 16-digit numeric sequences (potential card numbers)
3. Redacts strings matching email regex if the view is an `EditText` in a login context

---

## Agent 2: UsageGuardAgent

### What It Does
Queries Android's `UsageStatsManager` to build per-app foreground time summaries. This agent runs on a scheduled interval (every 15 minutes via `AlarmManager`) rather than listening continuously — it is **poll-based**, not event-based, making it extremely battery-efficient.

### Android Component
```
Class: UsageStatsWorker (WorkManager PeriodicWorkRequest)
Interval: 15 minutes
Constraints: No network required, battery not critically low
Permission: android.permission.PACKAGE_USAGE_STATS (user-granted)
```

### Functional Flow

```
UsageStatsWorker.doWork()
    │
    ▼
UsageStatsManager.queryAndAggregateUsageStats(
    startTime = lastRunTimestamp,
    endTime   = now
)
    │
    ▼
Filter to apps with foregroundTimeMs > 0
    │
    ▼
Map to AppUsageRecord {appId, packageName, foregroundMs, date}
    │
    ▼
Isar.write(records) — upsert by (packageName, date)
    │
    ▼
Emit summary to MethodChannel (for BLoC refresh on next UI open)
```

### Blacklist Enforcement Supplement
UsageGuardAgent also computes **daily quota violations**: if a blacklisted app's total foreground time exceeds its configured daily limit, it emits a `QuotaExceededEvent` which triggers a stricter overlay mode (overlay does not dismiss until next day).

---

## Agent 3: ScreenEventAgent

### What It Does
A `BroadcastReceiver` that captures every screen state transition event from the Android system. This is the source of truth for the **Device Unlock & Screen Logger**.

### Android Component
```
Class: KeroSpaceScreenReceiver extends BroadcastReceiver
Registration: Dynamic (registered in KeroSpaceForegroundService.onCreate())
  — NOT declared in manifest (runtime-registered receivers catch screen events reliably)

Intents Listened:
  ACTION_SCREEN_ON    → Screen woke from sleep
  ACTION_SCREEN_OFF   → Screen went to sleep
  ACTION_USER_PRESENT → Device unlocked (PIN/biometric cleared)
```

### Functional Flow

```
onReceive(context, intent) {
  val event = ScreenEvent(
    type      = classify(intent.action),  // WAKE | SLEEP | UNLOCK
    timestamp = System.currentTimeMillis(),
    deviceId  = Build.ID,
  )
  
  // Compute session duration on SLEEP events
  if (event.type == SLEEP) {
    val lastWake = SessionStateHolder.lastWakeTimestamp
    event.sessionDurationMs = event.timestamp - lastWake
  }
  
  EventChannel.sink.add(event.toJson())
  Isar.write(event)
}
```

### Derived Analytics (computed in BLoC, not agent)
- **Unlock frequency** per hour (heatmap source)
- **Average session length** per time-of-day
- **First unlock / last sleep** daily timestamps
- **Longest uninterrupted screen-off** (sleep quality proxy)

---

## Agent 4: WakeWordAgent

### What It Does
An always-on, fully offline voice activation system. The agent listens continuously to the microphone using Android's `AudioRecord` API, running audio frames through a local on-device wake-word detection model. It **never records audio to disk** and **never sends audio to any network endpoint**.

### Android Component
```
Class: WakeWordService extends Service
Type: Foreground Service (audio capture requires foreground classification)
Permission: android.permission.RECORD_AUDIO
Model: OpenWakeWord (ONNX Runtime on Android) or Porcupine offline SDK
```

### Technical Architecture

```
┌────────────────────────────────────────────────────────────┐
│  WAKE WORD PIPELINE                                        │
│                                                            │
│  AudioRecord (16kHz, 16-bit PCM, mono)                     │
│      │  160-frame buffer (~10ms chunks)                    │
│      ▼                                                     │
│  Mel Spectrogram Extractor (on-device, Kotlin/C++)         │
│      │                                                     │
│      ▼                                                     │
│  ONNX Runtime → WakeWord Model                             │
│  (e.g., "hey kero" custom model trained on ~500 samples)   │
│      │                                                     │
│      ▼                                                     │
│  Confidence score > threshold (0.85)?                      │
│      │ NO  → discard frame, continue                       │
│      │ YES ↓                                               │
│      ▼                                                     │
│  Emit WakeWordDetectedEvent to kero_space/wake_word channel│
│      │                                                     │
│      ▼                                                     │
│  Transition to CommandCapture mode:                        │
│    - Continue AudioRecord for up to 5 seconds              │
│    - Feed frames to on-device Whisper (tiny model)         │
│      for speech-to-text transcription                      │
│      │                                                     │
│      ▼                                                     │
│  Emit TranscriptionCompleteEvent{text} to channel          │
│    → Flutter VoiceBloc receives and processes command      │
└────────────────────────────────────────────────────────────┘
```

### Energy Efficiency Design
- Audio capture uses `PERFORMANCE_MODE_POWER_SAVING` AudioRecord mode
- Frame processing runs on a dedicated `HandlerThread` (not main thread)
- Model inference runs on a background thread pool (2 threads max)
- In doze mode: the service requests `PARTIAL_WAKE_LOCK` only during active listening confirmation (post-wake-word), not during idle monitoring
- Battery impact target: < 2% per hour of always-on listening (comparable to always-on fitness trackers)

### Command Processing in Flutter (VoiceBloc)
```
WakeWordDetected
    → VoiceBloc emits VoiceListeningState
    → Rive animation activates (waveform)

TranscriptionReceived(text)
    → VoiceBloc runs CommandParser.parse(text)
    → Intent classified: {domain, action, parameters}
    → Dispatches to appropriate BLoC:
        "add task buy groceries" → ProductivityBloc(AddTask)
        "log meal 200g chicken"  → HealthBloc(LogMeal)
        "show portfolio"         → FinanceBloc(NavigatePortfolio)
        "mark mass today"        → ChurchBloc(MarkAttendance)
    → VoiceBloc emits CommandExecutedState(result)
```

---

## Agent Lifecycle Management

### KeroSpaceForegroundService
All agents are coordinated under a single foreground service:

```
KeroSpaceForegroundService (extends Service)
  onCreate()
    → binds KeroSpaceAccessibilityService (via Intent check)
    → registers KeroSpaceScreenReceiver (BroadcastReceiver)
    → starts WakeWordService (bound service)
    → schedules UsageStatsWorker (WorkManager)
    → shows persistent notification (non-dismissible)

  onDestroy()  [called only if system kills service]
    → unregisters KeroSpaceScreenReceiver
    → stops WakeWordService
    → cancels pending WorkManager tasks (they re-enqueue on next boot)

  onStartCommand() → START_STICKY (service restarts automatically)
```

### Boot Persistence
```
KeroSpaceBootReceiver extends BroadcastReceiver
  Intent: ACTION_BOOT_COMPLETED, ACTION_MY_PACKAGE_REPLACED
  Action: startForegroundService(KeroSpaceForegroundService)
```

### Battery Optimization Exemption
The app must request `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` from the user during onboarding. The onboarding flow includes a guided deep-link to the exact Android settings screen for this exemption — no manual navigation required.

---

## Development Methodology & Verification (MANDATORY)

To ensure the reliability of the Omniscient Layer and its integrations, all future development on background services, features, or any app functionalities MUST strictly adhere to the following rules:

1. **Test-Driven Development (TDD)**:
   - Before writing implementation code for any new service, functionality, or BLoC, you MUST write failing unit tests or integration tests.
   - For native Android code (Kotlin), use JUnit/Robolectric or instrumented tests to verify Intents, Service bindings, and Room/Isar interactions.
   - For Dart code, use `flutter test` for BLoCs, repositories, and UI widgets.

2. **Mandatory Build & Analysis Checks**:
   - Before claiming any work is complete, you MUST run static analysis: `flutter analyze` for Dart code, and Android Lint/Detekt for Kotlin.
   - You MUST run a full debug build (`flutter build apk --debug` or `./gradlew assembleDebug`) to verify that native code compiles correctly without syntax or dependency errors.
   - Never commit code that fails analysis, has unresolved warnings, or fails to build. Evidence of success (build output/test output) must precede assertions of completion.

3. **Production Quality Standards (Anti-Placeholder Protocol)**:
   - **No Lazy Implementation:** You are forbidden from creating "placeholder" pages, returning simple `Center(child: Text('Placeholder'))` widgets, or committing code with hardcoded generic colors (like `Colors.black` or `Colors.green`) in place of the established design system tokens (`AppTheme`).
   - **No Unimplemented Features:** If a screen or feature is requested, it must be built to a production-ready standard, complete with proper layout, robust error handling, loading states, and alignment with the `AppTheme` design system. If a feature is too complex to complete in one step, build a functionally complete MVP, not a blank placeholder.
   - **Strict Design System Compliance:** All UI elements must strictly adhere to the tokens defined in `lib/core/app_theme.dart`. Do not invent raw color or typography tokens inline.
   - **Complete Navigation:** All routes in `router.dart` must point to fully implemented screens with proper BLoC injection. Nested navigation must be implemented cleanly without Hero tag collisions (e.g., using `DefaultTabController` instead of nested `BottomNavigationBar`s).