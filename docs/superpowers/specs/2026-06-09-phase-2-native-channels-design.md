# Phase 2 — Android Native Platform Channels Design

## 1. Architecture & Data Flow
- **Core Orchestration**: `KeroSpaceForegroundService` maintains the persistent notification and keeps all agents alive.
- **Data Flow Mechanism**: We use the `flutter_background_service` package to run a headless Dart isolate. Native Kotlin agents emit events via MethodChannels/EventChannels to this headless Dart context.
- **Database Access**: The Dart isolate writes `TelemetryEvent`, `ScreenEvent`, and `AppUsageRecord` to Isar DB. This avoids native Kotlin Isar schema duplication and C++ pointer conflicts.

## 2. Telemetry Agents
- **`KeroSpaceScreenReceiver`**: Dynamic receiver registered in the ForegroundService. Listens for `SCREEN_ON`, `SCREEN_OFF`, and `USER_PRESENT`. Emits JSON payloads to Dart.
- **`UsageStatsWorker`**: A WorkManager periodic job running every 15 minutes. Queries `UsageStatsManager` for foreground app time and emits JSON to Dart.

## 3. Overlay & Scrolling Blocker
- **`KeroSpaceAccessibilityService`**: Listens for `TYPE_WINDOW_STATE_CHANGED` and `TYPE_VIEW_CLICKED`. Emits active package names and clicks to Dart.
- **`OverlayManager`**: Manages a `TYPE_APPLICATION_OVERLAY` view. Displays the blocking UI (Rive countdown).
- **Control Logic**: Dart holds the blacklist and quota logic. When Dart receives a window state change for a blacklisted app, it evaluates the quota and calls `showOverlay` via MethodChannel if a block is required.

## 4. WakeWord Pipeline
- **`WakeWordService`**: Runs an `AudioRecord` 16kHz loop on a dedicated `HandlerThread`.
- **Inference**: For Phase 2 validation, the ONNX C++ JNI integration is deferred. Inference is stubbed and triggered via an ADB broadcast intent.
- **Emission**: Emits a `WakeWordDetectedEvent` to Dart, proving the pipeline is wired. Dart will handle Whisper transcription in later phases.
