# Trobio (Kero Space) — Project Status & Roadmap Handoff

## 1. Executive Summary

- **Audit Remediation**: **27 of 27 tasks complete (100%)**.
- **Static Analysis**: `flutter analyze` passes with **0 errors / 0 warnings**.
- **Design System**: Fully migrated to dynamic `AppTheme` with `ThemeExtension` (`context.appColors`).
- **Navigation**: 5 switchable paradigms (`CommandCapsule`, `ThreePillars`, `FloatingIsland`, `BentoHub`, `ClassicBar`) + Raycast-style `CommandRegistry` palette modal.
- **Native Android Daemons**: `KeroSpaceForegroundService`, `KeroSpaceAccessibilityService`, `SubAppDetector`, `CounterOverlayManager`, `UsageStatsWorker`, and `WakeWordService` fully implemented with headless isolate routing (`kero_space/bg/*`).

---

## 2. Completed Milestones Breakdown

### P0: Core Ship-Blockers (Completed)
- [x] **WakeWordService**: On-device micro-acoustic model trigger with command transcription pipeline.
- [x] **KeroSpaceForegroundService**: Sticky foreground coordinator with battery optimization exemption.
- [x] **AccessibilityService**: System-wide click telemetry & window state change detection.
- [x] **UsageStatsWorker**: 15-minute background WorkManager aggregation.
- [x] **OverlayManager & CounterOverlayManager**: Dynamic Decision Break countdown window over blacklisted apps.
- [x] **Platform PII Sanitization**: Real-time scrubbing of passwords, PINs, card numbers, and emails.
- [x] **CalendarChannelHandler**: Bi-directional bridge for local Samsung/Android Calendar Provider.

### P1: BLoC State Machines & Stability (Completed)
- [x] **VoiceBloc**: Command intent parser, intent confirmation modal, and cross-BLoC event dispatch.
- [x] **ConfessionBloc & EncryptedIsarConfessionsRepo**: Argon2id key derivation + AES-256-GCM client-side encryption.
- [x] **HealthBloc & NutritionRepository**: Egyptian food calorie engine, fasting macro toggle, OpenFoodFacts barcode scanner, OpenRouter AI vision scanner.
- [x] **ExerciseBloc & ExercisesRepository**: Configurable workout splits (PPL, Upper/Lower, Bro Split), exercise catalog, set/rep logging.
- [x] **FinanceBloc**: Double-entry ledger, bank SMS/notification parser, EGX stock portfolio tracker.
- [x] **ProductivityBloc & CalendarBloc**: Hierarchical tasks, carry-forward checklists, Quill Delta notes, Coptic Alexandrian Computus fasting cycles.
- [x] **ChurchBloc & CopticBloc**: Attendance streak heatmap, YouVersion daily scripture API, saint feasts tracker, Ministry Kanban.
- [x] **TelemetryBloc**: Screen time bar charts, blocker effectiveness analytics, unlock heatmaps, blacklist management.
- [x] **Widget Lifecycle Cleanups**: Fixed text/scroll controller disposal across all presentation views.

### P2: Design Tokens, Form Validation & Skeletons (Completed)
- [x] **Design System Token Compliance**: Replaced raw color literals with `AppTheme` and `context.appColors` tokens.
- [x] **CalorieConfigScreen Validators**: Added strict numeric validation (`double.tryParse`) for height, weight, and age.
- [x] **InlineErrorWidget & Shimmer Skeletons**: Standardized loading skeletons and retry widgets across all 6 core modules.
- [x] **Native Race Conditions & Preferences**: Synchronized `IsarService.init()` guards and encrypted blacklist storage.

---

## 3. Next-Phase Engineering Roadmap (Future Enhancements)

The following areas represent high-value opportunities for future sprints:

### Milestone 1: Self-Hosted Docker Sync Server
- [ ] Implement full batch ingestion (`POST /sync/batch`) and delta pull (`GET /sync/pull`) in `backend/bin/server.dart`.
- [ ] Implement PostgreSQL schema migrations matching Isar collections.
- [ ] Replace simulated sync in `lib/core/data/sync_worker.dart` with authenticated HTTPS/mTLS calls.
- [ ] Add exponential backoff retry policy for offline outbox queues.

### Milestone 2: Desktop OS Parity (Windows Platform Daemons)
- [ ] Implement Win32 foreground window hooks (`SetWinEventHook`, `GetForegroundWindow`) in `windows/runner/`.
- [ ] Expose native Windows process time tracking over `kero_space/win_process` channel.
- [ ] Create a desktop blocker overlay window for blacklisted desktop applications.

### Milestone 3: Zero-Cloud Local AI & Vision
- [ ] Replace cloud OpenRouter vision model with on-device quantized model (TFLite / ONNX Runtime) for Egyptian food recognition.
- [ ] Implement on-device Small Language Model (SLM) for natural language voice commands.
- [ ] Proactive ADHD nudge engine: detect rapid app switching loops and trigger cognitive grounding breaks.

### Milestone 4: Biometrics & Workout Audio/Haptics
- [ ] Integrate real-time rest timer with audio/haptic cues in `ExercisesTab`.
- [ ] Implement 1RM (one-rep max) calculations and progressive overload tracking.
- [ ] Deep Health Connect integration: read continuous HRV, resting heart rate, and sleep staging.

---

## 4. Verification & Testing Commands

```bash
# Verify static analysis
flutter analyze

# Run unit and BLoC tests
flutter test

# Run Android debug build
flutter build apk --debug

# Check for hardcoded color anti-patterns
rg "Colors\." lib/ --type dart -c
```