# agents.md — Background Agent & Native Daemon Specification

## 1. Overview

The **Omniscient Layer** is powered by persistent Android Services, BroadcastReceivers, and native daemons operating under `android/app/src/main/kotlin/com/example/trobio/`. These daemons observe device interactions, classify behavioral patterns, enforce app boundaries, and pipe telemetry directly into the local Isar database.

All daemons operate with zero cloud reliance, local-first processing, and automated PII sanitization.

```
┌────────────────────────────────────────────────────────────────────────┐
│                    NATIVE DAEMON TOPOLOGY                              │
│                                                                        │
│   KeroSpaceForegroundService (Sticky Master Coordinator)               │
│   ├── KeroSpaceAccessibilityService (Click stream, Blocker triggers)   │
│   ├── SubAppDetector (Reels/Shorts vs Productive Context)              │
│   ├── OverlayManager & CounterOverlayManager (WindowManager Overlays)  │
│   ├── KeroSpaceScreenReceiver (Screen On/Off, Unlock Latency)          │
│   ├── UsageStatsWorker (WorkManager foreground app time aggregation)   │
│   ├── WakeWordService & TrobioVoiceInteractionService (Voice Assistant)│
│   └── BlacklistPreferencesStore (Encrypted native rules storage)       │
│                                                                        │
│   Dual Stream Pipeline:                                                │
│   • Main UI Isolate        ──→ kero_space/* channels                   │
│   • Headless BG Engine     ──→ kero_space/bg/* channels                │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Daemon Registry

### Daemon 1: KeroSpaceAccessibilityService (`KeroSpaceAccessibilityService.kt`)
- **Type**: `AccessibilityService`
- **Events Monitored**: `TYPE_WINDOW_STATE_CHANGED`, `TYPE_VIEW_CLICKED`, `TYPE_VIEW_TEXT_CHANGED`
- **Responsibilities**:
  1. **App Boundary Enforcement**: Checks active package against `BlacklistPreferencesStore`.
  2. **Sub-App Detection (`SubAppDetector.kt`)**: Distinguishes between standard app usage and addictive micro-video feeds (e.g. YouTube Shorts vs regular educational videos; Instagram Reels vs direct messages).
  3. **Overlay Trigger**: Triggers `CounterOverlayManager` or `OverlayManager` to render a system overlay window when an unauthorized app or sub-feed is accessed.
  4. **Click Stream Logging**: Captures user click coordinates and UI element identifiers with automated PII scrubbing (passwords, PINs, card numbers, email addresses).

### Daemon 2: Blocker Overlays (`OverlayManager.kt` & `CounterOverlayManager.kt`)
- **Window Type**: `WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY`
- **Flags**: `FLAG_NOT_FOCUSABLE` (during countdown), `FLAG_LAYOUT_IN_SCREEN`, `FLAG_WATCH_OUTSIDE_TOUCH`
- **Responsibilities**:
  - `CounterOverlayManager`: Displays a floating or full-screen countdown timer with real-time seconds remaining, enforcing mandatory cognitive friction before allowing bypass.
  - Emits `BLOCKER_DECISION` telemetry events (`ALLOW`, `BLOCKED`, `BYPASS_PUZZLE`) over platform event channels.
  - Clean dismissal when the decision break expires or when the user navigates away to an allowed app.

### Daemon 3: Screen Lifecycle Monitor (`KeroSpaceScreenReceiver.kt`)
- **Type**: `BroadcastReceiver`
- **Events**: `Intent.ACTION_SCREEN_ON`, `Intent.ACTION_SCREEN_OFF`, `Intent.ACTION_USER_PRESENT`
- **Telemetry**:
  - Computes `sessionDurationMs = event.timestamp - lastWakeTimestamp` on screen lock.
  - Logs daily unlock frequencies and awake/sleep timestamps directly to Isar.

### Daemon 4: Usage Stats Worker (`UsageStatsWorker.kt`)
- **Type**: `PeriodicWorkRequest` (WorkManager, 15-minute interval)
- **Permission**: `android.permission.PACKAGE_USAGE_STATS`
- **Responsibilities**: Aggregates foreground time per package and writes daily buckets to local storage.

### Daemon 5: Voice Assistant & System Voice Interaction
- **Components**:
  - `WakeWordService.kt`: Background audio recorder running low-power acoustic detection for "Hey Kero" / "Trobio".
  - `TrobioVoiceInteractionService.kt` & `TrobioVoiceInteractionSessionService.kt`: Native Android Voice Interaction Service integration, allowing Trobio to handle hardware assistant triggers and system voice queries.

### Daemon 6: Encrypted Rule Store (`BlacklistPreferencesStore.kt`)
- Stores blacklist package configurations, daily time limits, and schedule windows using encrypted SharedPreferences. Ensures the accessibility service can evaluate blocking rules instantaneously without waiting for Flutter isolate IPC.

---

## 3. Dual-Channel Routing & Headless Isolate

To guarantee uninterrupted telemetry recording even when the Flutter activity is closed, Trobio utilizes two parallel channel structures:

1. **Main UI Engine (`kero_space/*`)**:
   - Handles active user interactions, voice command confirmations, and on-screen telemetry dashboard refreshes.
2. **Headless Background Engine (`kero_space/bg/*`)**:
   - Initialized via `@pragma('vm:entry-point') void backgroundMain()` in [kero_space_platform_service.dart](file:///c:/projects/Flutter/kero_space/lib/core/data/kero_space_platform_service.dart#L50).
   - Dedicated headless FlutterEngine spawned by Android services.
   - Listens to `kero_space/bg/screen_events` and `kero_space/bg/accessibility`.
   - Sanitizes data and performs direct atomic writes to Isar without routing through the UI thread.

---

## 4. Boot Persistence & Battery Policies

- **Boot Receiver (`KeroSpaceBootReceiver.kt`)**: Automatically starts `KeroSpaceForegroundService` on `ACTION_BOOT_COMPLETED` and `ACTION_MY_PACKAGE_REPLACED`.
- **Battery Optimization Exemption**: Uses `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` to prevent OEM power managers from killing accessibility and wake-word daemons during deep sleep.
- **Service Restart**: `KeroSpaceForegroundService.onStartCommand()` returns `START_STICKY`.

---

## 5. Development Methodology & Verification (MANDATORY)

All modifications to native Android code or Flutter background services must follow this standard:

1. **Skill-First Workflow**:
   - `kotlin-specialist` for any changes in `android/app/src/main/kotlin/`.
   - `flutter-expert` for platform channel Dart interfaces and isolate handlers.
   - `systematic-debugging` for race conditions, isolate deadlocks, or IPC crashes.

2. **Analysis & Build Gates**:
   - `flutter analyze`: Must pass with 0 errors before committing changes.
   - `./gradlew assembleDebug` or `flutter build apk --debug`: Must compile cleanly.
   - Run unit tests (`flutter test`) verifying BLoC state transitions and command parsing.

3. **No Stub/Placeholder Implementations**:
   - Every background event, channel handler, and overlay must be fully functional.
   - All color tokens in overlays or dialogs must reference `AppTheme` tokens.