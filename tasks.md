# tasks.md — Production Implementation Roadmap

## Engineering Philosophy

This roadmap is structured for a **solo principal engineer** with full-stack and mobile competency. It is sequenced by **risk-first** principles: the hardest platform integrations (Accessibility Services, Health Connect, native channels) are validated early, before any CRUD feature work begins. Building UIs on top of broken OS integrations wastes weeks.

Each phase has a **Definition of Done (DoD)** — tasks are not complete until the DoD criteria are met.

**Phase Review & Completion Rule:** After completing the tasks for a phase, you must thoroughly review the implementation. If the phase is fully implemented and production-ready, mark it as completed. If there are gaps, bugs, or missing requirements, revisit the tasks and complete them before checking off the phase.

---

## Phase 0 — Project Scaffolding & DevOps Foundation
*Target duration: 3–5 days*

### Goals
Establish the monorepo, CI pipeline, and Docker backend skeleton so every subsequent phase delivers into a working system.

### Tasks

- [x] **0.1** Initialize Flutter project with package structure:
  ```
  lib/
    core/           # DI, routing, theme (strictly in lib/core/app_theme.dart)
    features/
      telemetry/   # BLoC, data, domain, presentation
      productivity/
      health/
      finance/
      church/
      voice/
    shared/          # Common helpers, charts, and shared widgets
      widgets/       # Single folder containing ALL refactored, reusable UI components
  ```
  Use `very_good_cli` or manual structure following Clean Architecture conventions.

- [x] **0.2** Add and configure all dependencies in `pubspec.yaml`:
  - `flutter_bloc`, `equatable` — state management
  - `isar`, `isar_flutter_libs` — local database
  - `fl_chart` — data visualization
  - `rive` — Rive animation runtime
  - `flutter_secure_storage` — hardware-backed secrets
  - `dio` — HTTP client for Docker API
  - `get_it` + `injectable` — dependency injection
  - `health` — Android Health Connect
  - `go_router` — declarative navigation
  - `freezed`, `json_serializable` — code generation

- [x] **0.3** Implement `AppTheme` strictly within a single file `lib/core/app_theme.dart` containing all color tokens, typography scales, light/dark mode definitions, and visual decorations. No hardcoded colors are allowed anywhere else in the codebase.

- [x] **0.4** Configure `go_router` with all top-level routes. Stub all feature screens with `PlaceholderScreen(featureName)`.

- [x] **0.5** Set up Docker backend skeleton:
  - `docker-compose.yml` with `kero-space-api`, `kero-space-postgres`, `kero-space-redis`, `kero-space-caddy` services
  - PostgreSQL init script with all table schemas (with `updated_at` triggers)
  - Caddy with self-signed TLS config
  - API server stub (Dart Shelf or Rust Actix) returning `200 OK` on `/health`

- [x] **0.6** Set up GitHub Actions (or Gitea if self-hosted):
  - `flutter analyze` + `flutter test` on every push
  - Docker image build + push to local registry on merge to `main`

- [x] **0.7** Configure Android `AndroidManifest.xml` with all permissions declared (not yet granted):
  - `BIND_ACCESSIBILITY_SERVICE`, `PACKAGE_USAGE_STATS`, `SYSTEM_ALERT_WINDOW`, `RECORD_AUDIO`, `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

**DoD:** `flutter run` launches on Android with a themed shell. Docker `docker-compose up` starts all services with healthy status. CI passes.

---

## Phase 1 — Isar Schema & Core Data Layer
*Target duration: 4–6 days*

### Goals
Define all Isar collections and the sync outbox mechanism. Every feature in later phases writes to this schema.

### Tasks

- [x] **1.1** Define Isar collections for all domains:
  ```dart
  // Core schemas will include deviceId and platform fields for Android <-> Windows sync tracking
  @Collection() class TelemetryEvent { ... }
  @Collection() class AppUsageRecord { ... }
  @Collection() class ScreenEvent { ... }
  @Collection() class Task { ... }
  @Collection() class Note { ... }
  @Collection() class CalendarEvent { ... }
  @Collection() class HealthRecord { ... }
  @Collection() class MealEntry { ... }
  @Collection() class Ingredient { ... }
  @Collection() class Invoice { ... }
  @Collection() class Transaction { ... }
  @Collection() class EGXHolding { ... }
  @Collection() class EGXPriceSnapshot { ... }
  @Collection() class MassAttendance { ... }
  @Collection() class ConfessionEntry { ... }  // stored as encrypted bytes only
  @Collection() class MinistryTask { ... }
  @Collection() class SyncOutboxRecord { ... }
  ```
  Run `flutter pub run build_runner build` to generate Isar adapters.

- [x] **1.2** Implement `IsarService` singleton — opens the Isar instance with encryption key (loaded from `flutter_secure_storage` on first run, generated if absent).

- [x] **1.3** Implement `SyncOutboxRepository`:
  - `addToOutbox(entity, operation)` — writes a `SyncOutboxRecord` with `PENDING` status
  - `getPendingBatch(limit: 50)` — retrieves oldest PENDING records
  - `markSynced(ids)` / `markFailed(ids, error)` — status updates

- [x] **1.4** Implement `SyncWorker` (Dart isolate):
  - Runs every 30 seconds when Docker is reachable
  - Calls `SyncOutboxRepository.getPendingBatch()`, POSTs to `/sync/batch`, updates statuses
  - Handles 409 Conflict from server: applies Last-Write-Wins by default

- [x] **1.5** Seed the **Ingredient Database** into Isar from a local JSON file (source: Open Food Facts offline export filtered to Egyptian common foods + standard staples). ~3,000 ingredients minimum.

- [x] **1.6** Write unit tests for all repository implementations (mock Isar with `isar_test`).

**DoD:** All collections openable. Outbox write/read cycle verified in tests. Ingredient seed completes < 5s on device.

---

## Phase 2 — Android Native Platform Channels
*Target duration: 5–7 days*

### Goals
Validate all four OS-level platform channels before any Flutter feature work. This is the highest-risk phase.

### Tasks

- [x] **2.1** Implement `KeroSpaceForegroundService` in Kotlin:
  - Persistent notification with "Kero Space Active" status
  - `START_STICKY` restart policy
  - `KeroSpaceBootReceiver` for boot persistence

- [x] **2.2** Implement `KeroSpaceScreenReceiver`:
  - Register in `KeroSpaceForegroundService.onCreate()`
  - Emit `{type, timestamp}` JSON to `kero_space/screen_events` EventChannel
  - Write `ScreenEvent` to Isar via `ContentValues` (Kotlin-side Isar write)
  - **Validate:** Lock/unlock device 10 times, verify 10 UNLOCK events appear in Flutter BLoC state

- [x] **2.3** Implement `KeroSpaceAccessibilityService`:
  - Config XML with event types as specified in `agents.md`
  - Emit filtered click events to `kero_space/accessibility` EventChannel
  - **Validate:** Open Instagram, verify `TypeWindowStateChanged` event is received in Flutter with correct `packageName`

- [x] **2.4** Implement Overlay Window (`OverlayManager`):
  - `showOverlay(packageName, durationSeconds)` MethodChannel handler
  - Creates `TYPE_APPLICATION_OVERLAY` window with countdown timer
  - `dismissOverlay()` handler
  - **Validate:** Invoke overlay from Flutter, verify it appears over all apps, verify it dismisses on timer

- [x] **2.5** Wire Scrolling Blocker logic:
  - `AccessibilityService.onAccessibilityEvent()` checks `BlacklistRepository` (reads from Isar)
  - Calls `OverlayManager.showOverlay()` on match
  - **Validate:** Add Instagram to blacklist in app, open Instagram, overlay appears within 500ms

- [x] **2.6** Implement `UsageStatsWorker` (WorkManager):
  - 15-minute periodic query of `UsageStatsManager`
  - Writes `AppUsageRecord` list to Isar
  - **Validate:** Run for 1 hour, verify 4 worker executions in Logcat, Isar contains usage records

- [x] **2.7** Implement `WakeWordService`:
  - `AudioRecord` setup at 16kHz, 16-bit PCM
  - ONNX Runtime integration with a placeholder model (use a pre-trained "hey siri" style model for testing)
  - Emit detection event to `kero_space/wake_word` EventChannel
  - **Validate:** Model detects test phrase at least 90% of the time from 1 meter in quiet room

- [x] **2.8** Wire all channels to Dart `EventChannel`/`MethodChannel` counterparts and abstract as `KeroSpacePlatformService` interface (injected via GetIt).

**DoD:** All 4 agents operating simultaneously. Device runs for 4 hours with no ANR, no crash, battery drain < 8% above baseline.

---

## Phase 3 — Productivity Module (Tasks, Notes, Calendar)
*Target duration: 5–7 days*

### Tasks

- [ ] **3.1** `ProductivityBloc` implementation with full event/state coverage
- [ ] **3.2** Task CRUD screens: list, create (with priority + parent task picker), detail, complete
- [ ] **3.3** Multi-tiered task dependency rendering (tree view with `flutter_fancy_tree_view` or custom `CustomPainter`)
- [ ] **3.4** Daily checklist view with carry-forward logic (incomplete tasks from yesterday auto-appear)
- [ ] **3.5** Notes CRUD with rich text support (`flutter_quill`)
- [ ] **3.6** Samsung Calendar platform channel (`kero_space/calendar`):
  - Kotlin reads from `CalendarContract.Events` ContentProvider
  - Returns events as JSON to Flutter
- [ ] **3.7** Google Calendar OAuth2 integration:
  - PKCE flow using `flutter_appauth`
  - Tokens stored in `flutter_secure_storage`
  - `GoogleCalendarRepository` implementation using raw `dio` HTTP calls to Calendar REST API v3
  - **No Google Sign-In SDK** — private OAuth client only
- [ ] **3.8** Unified `CalendarBloc` merging Samsung + Google events into a single sorted stream
- [ ] **3.9** Calendar UI: month view + day view using `table_calendar` (customized to match Kero Space theme)
- [ ] **3.10** Implement dynamic Coptic Orthodox Fasting Calendar Computus algorithm to automatically calculate and highlight shifting fasts (Great Lent, Apostles' Fast, Jonah's Fast, weekly Wednesday/Friday fasts) based on Orthodox Pascha calculation.
- [ ] **3.11** ADHD visual adjustments: dynamic task carry-forward visual styling, breathing monochrome white gradient on active pinned focus tasks, custom light haptic triggers, and particle Canvas splash on check-offs.

**DoD:** Tasks persist across app restarts. Calendar shows events from both sources. Google OAuth refresh token survives app restart. Fasting dates calculated dynamically and highlighted correctly.

---

## Phase 4 — Health Module (Biometrics + Nutrition)
*Target duration: 5–6 days*

### Tasks

- [ ] **4.1** Health Connect integration via `health` package:
  - Request permissions: `STEPS`, `HEART_RATE`, `SLEEP_SESSION`
  - `HealthConnectRepository` polling every 30 minutes via WorkManager
  - Write to `HealthRecord` Isar collection
- [ ] **4.2** `HealthBloc` with states for steps, heart rate, sleep
- [ ] **4.3** Health Dashboard UI:
  - Weekly steps bar chart (fl_chart `BarChart`)
  - Heart rate line chart with 24h data
  - Sleep stages radar chart
  - Today's summary card with ring indicators
- [ ] **4.4** Calorie Engine:
  - `IngredientSearchScreen`: search local Isar ingredient DB by name (debounced Isar query)
  - `MealLogScreen`: weight input (grams) → auto-computed calories + macros
  - `DailySummary` calculation: sum of all meals vs. configurable target
- [ ] **4.5** Calorie target configuration screen (BMR calculator: weight, height, age, activity level → Mifflin-St Jeor formula)
- [ ] **4.6** Calorie history chart (14-day bar chart: daily surplus/deficit)
- [ ] **4.7** Seed local database with Egyptian food items (Ful Medames, Falafel/Ta'ameya, Koshary, etc.) and precalculate macro density. Implement Coptic Fasting macro logic (toggle switch) dynamically adjusting macros to plant-based ratios and alerting on animal products.

**DoD:** Steps from Honor Watch visible in app within 30 minutes of activity. Meal logging persists and sums correctly. Charts render with real data. Egyptian foods searchable. Fasting mode changes macro constraints.

---

## Phase 5 — Finance Module (Ledger + EGX)
*Target duration: 7–9 days*

### Tasks

- [ ] **5.1** Double-entry bookkeeping data model:
  - `Account` (asset, liability, income, expense, equity)
  - `JournalEntry` (debit account, credit account, amount, currency, date, memo)
  - Multi-currency: amounts stored in minor units (piasters) with currency code; display converted at snapshot rate
- [ ] **5.2** `FinanceBloc` with events for all ledger operations
- [ ] **5.3** Invoice management:
  - Client CRUD
  - Invoice create/edit (line items, due date, currency)
  - Invoice status flow: DRAFT → SENT → PARTIALLY_PAID → PAID → OVERDUE
  - PDF export (`pdf` package) for invoice documents
- [ ] **5.4** Payment recording (links payment to invoice, creates journal entry)
- [ ] **5.5** Financial reports:
  - Monthly income statement
  - Cash flow timeline chart
  - Outstanding receivables list with aging brackets
- [ ] **5.6** EGX Portfolio Tracker:
  - `EGXHolding` CRUD (ticker, quantity, average cost basis, purchase date)
  - EGX price scraper (Kotlin `OkHttp` running on Docker backend as a scheduled job, or on-device via `dio` hitting EGX public website with HTML parsing using `html` package)
  - `EGXPriceSnapshot` written to Isar every market-open polling cycle (15 minutes during trading hours 10:00–14:30 EET)
  - Portfolio valuation: `(currentPrice - avgCost) * quantity` per holding
  - Dividend yield tracking (manual entry of dividend records)
- [ ] **5.7** Multi-axis correlation chart: earnings + portfolio + caloric balance (the flagship visualization described in `design.md`)
- [ ] **5.8** Currency rate management: manual rate entry UI + optional local scraping of CBE exchange rates
- [ ] **5.9** Build MIS-aligned financial reports (balance sheets, debit/credit journal charts matching academic curricula) and set up the Career Preparation Kanban module tracking banking job targets, tech certs, and freelance client pipelines.

**DoD:** Invoice creates journal entries automatically. Portfolio value updates within 15 minutes of price change during trading hours. Multi-axis chart renders all three data series with correct Y-axis scaling. Career Kanban tracks job/certification progress.

---

## Phase 6 — Church Module (Spiritual + Ministry)
*Target duration: 4–5 days*

### Tasks

- [ ] **6.1** `ChurchBloc` with all attendance and ministry states
- [ ] **6.2** Mass Attendance tracker:
  - Single-tap mark attendance for today
  - Retroactive date picker (mark past dates)
  - Streak calculation (longest current streak, all-time longest)
  - Contribution grid UI (52-week × 7-day `CustomPainter`, iOS system purple or monochrome white/gray color scale)
  - Monthly/yearly statistics cards
- [ ] **6.3** Confessions Log:
  - Passphrase setup screen (first time): derives AES-256-GCM key via `Argon2id(passphrase, randomSalt)`; salt stored in `flutter_secure_storage`; key NEVER stored
  - Session: user enters passphrase → key derived in memory → unlocks decryption for session lifetime → auto-locks after 10 minutes idle
  - Entry create: plaintext composed in memory → encrypted to bytes → stored as `List<int>` in Isar `ConfessionEntry.encryptedPayload`
  - Entry read: retrieve bytes → decrypt with session key → display
  - No backup, no sync, no cloud — `ConfessionEntry` is excluded from `SyncOutboxRepository`
- [ ] **6.4** Ministry Management:
  - Member records CRUD (name, role, contact, join date)
  - Service task board (Kanban-style: TODO → IN_PROGRESS → DONE)
  - Lesson plan editor (structured Markdown with `flutter_quill`)
- [ ] **6.5** Church notifications: local `flutter_local_notifications` for scheduled reminders (confession due, upcoming service task deadlines)

**DoD:** Confessions entry encrypted in Isar (verify via Isar Inspector — raw bytes not readable). Attendance streak calculates correctly across month boundaries. Ministry board persists task state.

---

## Phase 7 — Telemetry Dashboard & Behavioral Analytics
*Target duration: 4–5 days*

### Goals
Surface all telemetry data collected by the agents into actionable, glanceable visualizations.

### Tasks

- [ ] **7.1** `TelemetryBloc` aggregating data from all three telemetry repositories (screen events, usage stats, click logs)
- [ ] **7.2** Screen Time Overview screen:
  - Today's total screen time (hero metric)
  - App usage pie chart (fl_chart `PieChart`, top 8 apps)
  - Daily trend line (7-day screen time history)
- [ ] **7.3** Unlock pattern heatmap:
  - `CustomPainter` grid: 7 days × 24 hours, color intensity = unlock count
  - Tap a cell to see raw timestamps for that hour
- [ ] **7.4** Blocker effectiveness dashboard:
  - Blocked attempts vs. granted overrides per app per day
  - "Resistance rate" metric: (blocked / total attempts) × 100%
  - Weekly trend bar chart
- [ ] **7.5** Blacklist management screen:
  - Add/remove apps (shows installed apps list with icons)
  - Per-app configuration: allowed windows, daily quota, Decision Break duration
- [ ] **7.6** Click log browser:
  - Filterable by app, date range
  - Timeline view showing click density per hour
- [ ] **7.7** Implement the Omniscient Control Center settings screen:
  - 2x2 toggle status grid binding Accessibility, UsageGuard, ScreenEvent, and WakeWord agents.
  - Blacklist rule manager interface allowing configuration of allowed hours, custom Decision Break countdown times, and Soft vs Hard lockout strictness.
  - Emergency bypass overlay keypad triggering puzzle verification and logging bypass events.

**DoD:** All three telemetry charts render with 7+ days of real collected data. Blacklist configuration changes take effect within one accessibility event cycle. Blocker settings are modifiable and applied at runtime.

---

## Phase 8 — Voice Command System
*Target duration: 3–4 days*

### Tasks

- [ ] **8.1** `VoiceBloc` with full state machine (Idle → WakeWordDetected → Listening → Processing → Success/Failure)
- [ ] **8.2** `CommandParser` — rule-based NLP (no ML required for v1):
  - Intent classification by keyword matching + regex patterns
  - Entity extraction: task names, meal names, amounts, dates
  - Map intents to BLoC events
- [ ] **8.3** Voice Command UI:
  - Bottom sheet that auto-opens on wake word
  - Rive waveform animation (responds to detected wake word)
  - Transcription displayed live as Whisper emits partial results
  - Command result card (success/failure with action summary)
- [ ] **8.4** Whisper on-device integration:
  - `whisper.cpp` compiled for Android ARM64 via Flutter FFI
  - Tiny model (~75MB) bundled in assets
  - Transcription runs in background isolate (no UI freeze)
- [ ] **8.5** Wake word custom model training documentation:
  - README with instructions for recording 500 samples of "hey kero" and training with OpenWakeWord
  - Script for model export to ONNX format
  - Integration testing checklist

**DoD:** "Hey Kero, log 150g rice" → HealthBloc receives `LogMeal(name: 'rice', grams: 150)` and executes. "Hey Kero, add task review contracts" → task appears in task list. False positive rate < 1 per hour.

---

## Phase 9 — Windows Desktop Adaptation
*Target duration: 3–4 days*

### Tasks

- [ ] **9.1** Implement Windows platform channel (`kero_space/win_process`):
  - Dart FFI binding to `user32.dll` `GetForegroundWindow` + `GetWindowText`
  - Poll every 5 seconds, emit process change events to `ProcessEventBloc`
- [ ] **9.2** Adaptive layout: implement `AdaptiveLayout` widget that switches between mobile (bottom nav) and desktop (left rail) based on `MediaQuery.size.width > 800`
- [ ] **9.3** Desktop-specific: keyboard shortcuts (`flutter_shortcuts`):
  - `Ctrl+N` → New task
  - `Ctrl+Shift+M` → Mark mass today
  - `Ctrl+L` → Log meal
  - `Ctrl+/` → Voice command input (text fallback on Windows)
- [ ] **9.4** Windows-specific window management:
  - `window_manager` package for custom title bar, minimize-to-tray
  - System tray icon with quick-action menu
- [ ] **9.5** Docker backend connectivity on Windows:
  - If backend is on same machine: `localhost:8443`
  - If backend is on home server: mDNS discovery or configurable IP

**DoD:** App runs on Windows without crashes. Dashboard renders in two-column layout. Keyboard shortcuts work.

---

## Phase 10 — Polish, Hardening & Production Readiness
*Target duration: 5–7 days*

### Tasks

- [ ] **10.1** Onboarding flow: permission request sequence with guided deep-links to Android settings
- [ ] **10.2** Error handling: global `ErrorBloc` with Snackbar/Dialog presentation for all repository errors
- [ ] **10.3** Loading skeleton shimmer for all data-driven screens
- [ ] **10.4** App performance profiling:
  - Flutter DevTools timeline trace: target 60fps on all animated screens
  - Isar query optimization: add missing indexes, analyze slow queries
- [ ] **10.5** Accessibility: semantic labels on all interactive widgets, screen reader compatibility for primary flows
- [ ] **10.6** Data export: JSON/CSV export of all non-encrypted data (privacy right to your own data)
- [ ] **10.7** Docker backup script: `pg_dump` + Isar file backup to local external drive on schedule
- [ ] **10.8** Integration test suite: `flutter_test` + `integration_test` for all critical user flows
- [ ] **10.9** Security audit:
  - Verify no plaintext confessions in Isar with Isar Inspector
  - Verify no PII in logcat output
  - Verify TLS certificate pinning rejects tampered cert
- [ ] **10.10** Release build configuration:
  - Android: ProGuard rules, signed APK with your own keystore
  - Windows: MSIX packaging with self-signed certificate

**DoD:** App survives 24-hour soak test on Android with all agents running. Zero accessibility crashes. Security audit passes all checklist items. Docker backup restores successfully on clean PostgreSQL instance.

---

## Dependency Map

```
Phase 0 (Scaffold)
    └→ Phase 1 (Isar Schema)
           └→ Phase 2 (Native Channels)
                  ├→ Phase 3 (Productivity)
                  ├→ Phase 4 (Health)
                  ├→ Phase 5 (Finance)
                  ├→ Phase 6 (Church)
                  ├→ Phase 7 (Telemetry Dashboard)  ← requires Phase 2 data
                  └→ Phase 8 (Voice)
                         └→ Phase 9 (Windows)
                                └→ Phase 10 (Polish)
```

Phases 3–7 can be developed in **parallel** after Phase 2 is complete. A solo engineer should sequence them by personal priority: Health → Productivity → Finance → Church → Telemetry is a reasonable order since Health Connect validation catches early Android API issues.

---

## Estimated Total Timeline

| Phase | Duration |
|---|---|
| 0 — Scaffolding | 3–5 days |
| 1 — Data Layer | 4–6 days |
| 2 — Native Channels | 5–7 days |
| 3 — Productivity | 5–7 days |
| 4 — Health | 5–6 days |
| 5 — Finance | 7–9 days |
| 6 — Church | 4–5 days |
| 7 — Telemetry | 4–5 days |
| 8 — Voice | 3–4 days |
| 9 — Windows | 3–4 days |
| 10 — Polish | 5–7 days |
| **Total** | **~55–70 working days** |

At 4 productive hours/day alongside other commitments: **~14–18 weeks** to a stable v1.0.