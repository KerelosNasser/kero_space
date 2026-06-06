# agents.md — Background Agent Specification

## Overview

The "Omniscient Layer" is powered by four persistent background agents, each operating as an independent Android Service or system-level component. These agents are the sensory nervous system of ALEF — they observe, classify, and pipe behavioral data into the Isar cache continuously, regardless of whether the Flutter UI is active.

All agents are architecturally **push-based**: they emit events into named platform channels, which the Flutter EventChannel listeners receive and forward to the relevant BLoC.

```
┌─────────────────────────────────────────────────────────────────┐
│                    AGENT ARCHITECTURE                           │
│                                                                 │
│  Agent 1: AccessibilityAgent  ──→  alef/accessibility channel  │
│  Agent 2: UsageGuardAgent     ──→  alef/usage_stats channel    │
│  Agent 3: ScreenEventAgent    ──→  alef/screen_events channel  │
│  Agent 4: WakeWordAgent       ──→  alef/wake_word channel      │
│                                                                 │
│  All agents bound to AlefForegroundService (persistent)         │
│  Foreground notification: minimal, non-dismissible              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Agent 1: AccessibilityAgent

### What It Does
The `AccessibilityAgent` is an `AccessibilityService` implementation that monitors UI interactions system-wide. It is the engine behind both the **Mindless Scrolling Blocker** and the **System-Wide Click Logger**.

### Android Component
```
Class: AlefAccessibilityService extends AccessibilityService
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
Class: AlefScreenReceiver extends BroadcastReceiver
Registration: Dynamic (registered in AlefForegroundService.onCreate())
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
│  (e.g., "hey alef" custom model trained on ~500 samples)   │
│      │                                                     │
│      ▼                                                     │
│  Confidence score > threshold (0.85)?                      │
│      │ NO  → discard frame, continue                       │
│      │ YES ↓                                               │
│      ▼                                                     │
│  Emit WakeWordDetectedEvent to alef/wake_word channel      │
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

### AlefForegroundService
All agents are coordinated under a single foreground service:

```
AlefForegroundService (extends Service)
  onCreate()
    → binds AlefAccessibilityService (via Intent check)
    → registers AlefScreenReceiver (BroadcastReceiver)
    → starts WakeWordService (bound service)
    → schedules UsageStatsWorker (WorkManager)
    → shows persistent notification (non-dismissible)

  onDestroy()  [called only if system kills service]
    → unregisters AlefScreenReceiver
    → stops WakeWordService
    → cancels pending WorkManager tasks (they re-enqueue on next boot)

  onStartCommand() → START_STICKY (service restarts automatically)
```

### Boot Persistence
```
AlefBootReceiver extends BroadcastReceiver
  Intent: ACTION_BOOT_COMPLETED, ACTION_MY_PACKAGE_REPLACED
  Action: startForegroundService(AlefForegroundService)
```

### Battery Optimization Exemption
The app must request `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` from the user during onboarding. The onboarding flow includes a guided deep-link to the exact Android settings screen for this exemption — no manual navigation required.