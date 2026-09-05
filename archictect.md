# architect.md — Structural Engineering Specification

## 1. High-Level Architecture Overview

Trobio is structured around three concentric layers enforcing strict **Dependency Inversion**:

```
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER  (Flutter UI + BLoC / Cubit State Machines) │
├─────────────────────────────────────────────────────────────────┤
│  DOMAIN LAYER        (Use Cases, Repositories, Entities)        │
├─────────────────────────────────────────────────────────────────┤
│  DATA LAYER          (Isar Cache ↔ Docker Backend ↔ OS Channels)│
└─────────────────────────────────────────────────────────────────┘
```

The domain layer remains completely decoupled from Flutter UI, Isar, HTTP, or platform channels. All external dependencies are injected via abstract repository interfaces registered in `lib/core/di/injection.dart`.

### Theming & Navigation Architecture Policies
- **Dynamic Theming System:** Defined in `lib/core/app_theme.dart` using a custom `ThemeExtension` (`AppColorsExtension` / `context.appColors`). Supports 11 curated theme presets plus user-configured palettes via `CustomThemeStudioScreen`.
- **Modular Navigation Systems:** Managed by `NavigationCubit` in `lib/core/navigation/`. The UI renders one of 5 distinct navigation layouts dynamically wrapped around `AppShell`:
  1. `CommandCapsuleNav` (with center Raycast-style `CommandPaletteModal`)
  2. `ThreePillarsNav` (Hierarchical domain switcher)
  3. `FloatingIslandDock`
  4. `BentoHubNav`
  5. `ClassicBar`
- **Shared Component Repository:** Reusable UI components (buttons, shimmers, cards, error displays) reside in `lib/shared/widgets/`. Local feature widgets live in `lib/features/[name]/presentation/widgets/`.

---

## 2. BLoC & Cubit State Flow

### Core Architecture Pattern
```
UI Widget / Command Palette
  │  dispatches Event / Action
  ▼
BLoC / Cubit
  │  calls Repository / Service (abstract interface)
  ▼
Repository Implementation
  │  reads/writes Isar (local) OR HTTP (Docker) / Platform Service
  ▼
Isar Database / OS Daemon
  │  emits result or stream update
  ▼
BLoC emits State
  │
  ▼
UI Widget rebuilds via BlocBuilder / BlocListener
```

### Complete BLoC & Cubit Registry

| Component | Scope / Lifetime | Events / Methods | Key States |
|---|---|---|---|
| `TelemetryBloc` | Singleton (Boot) | `LoadTelemetryDashboard`, `LoadBlacklist`, `UpdateBlacklistRule` | `TelemetryState` (todayScreenTimeMs, topApps, unlockCount, blockerStats) |
| `ProductivityBloc` | Singleton | `createTask`, `completeTask`, `createNote`, `deleteNote` | `ProductivityState` (tasks, notes, projectCards, deepWorkTimer) |
| `CalendarBloc` | Singleton | `LoadCalendarEvents`, `SyncDeviceCalendar` | `CalendarState` (events, copticFastingPeriods) |
| `HealthBloc` | Singleton | `LoadDashboard`, `LogMeal`, `UpdateCalorieConfig`, `ToggleFastingMode` | `HealthState` (steps, hr, calories, macros, isFastingMode) |
| `ExerciseBloc` | Factory | `LoadExercisesDashboard`, `SelectExerciseSplit`, `LogExerciseSet` | `ExerciseState` (availableSplits, selectedSplit, todayWorkout) |
| `FinanceBloc` | Singleton | `LoadFinanceData`, `AddTransactionEvent`, `RefreshEGXQuotes` | `FinanceState` (transactions, budgets, subscriptions, egxHoldings) |
| `ChurchBloc` | Singleton | `LoadChurchData`, `MarkAttendanceEvent`, `UpdateMinistryTask` | `ChurchState` (attendanceGrid, ministryMembers, serviceTasks) |
| `ConfessionBloc` | Singleton | `UnlockConfessions`, `LockConfessions`, `AddConfessionEntry` | `ConfessionState` (isUnlocked, entries, error) |
| `CopticBloc` | Singleton | `LoadCopticData` | `CopticState` (copticDayInfo, passageTexts, upcomingFeasts) |
| `VoiceBloc` | Singleton | `WakeWordTriggered`, `SpeechFinalResultEvent`, `ConfirmIntentEvent` | `VoiceIdle`, `VoiceListening`, `VoiceConfirmPending`, `VoiceSuccess` |
| `ThemeCubit` | Singleton | `setTheme(AppThemeId)`, `updateCustomConfig(CustomThemeConfig)` | `ThemeState` (activeThemeId, customConfig) |
| `NavigationCubit`| Singleton | `setNavigationMode(AppNavStyle)` | `NavigationState` (mode) |

---

## 3. Data & External Services Layer

External capabilities and integrations are encapsulated in dedicated service classes:

| Service | Location | Purpose |
|---|---|---|
| `IsarService` | `lib/core/data/isar_service.dart` | Thread-safe, multi-isolate initialization of local Isar database |
| `KeroSpacePlatformService` | `lib/core/data/kero_space_platform_service.dart` | Bridge for Android background isolate, rules, and overlay control |
| `BarcodeService` | `lib/features/health/data/services/barcode_service.dart` | OpenFoodFacts product nutrition lookup via barcode |
| `AiScannerService` | `lib/features/health/data/services/ai_scanner_service.dart` | Vision-based food nutrient estimation via OpenRouter API |
| `YouVersionService` | `lib/features/church/data/services/youversion_service.dart` | Liturgical daily scripture verse retrieval |
| `NotificationParserService` | `lib/features/finance/data/repositories/notification_parser_service.dart` | Bank SMS & push notification transaction auto-extraction |
| `EGXScraperService` | `lib/features/finance/data/repositories/egx_scraper_service.dart` | Egyptian Exchange ticker quotes & price scraper |
| `ConfessionCryptoService` | `lib/features/church/data/repositories/confession_crypto_service.dart` | Argon2id salt generation & AES-256-GCM encryption engine |
| `CommandRegistry` | `lib/core/navigation/command_registry.dart` | Action registry for Raycast-style ⌘ command palette modal |

---

## 4. Headless Background Isolate Architecture

Android background telemetry (screen cycles, clicks, app blockers) bypasses the main UI isolate to ensure zero UI frame drops and 100% telemetry capture when the app is minimized or suspended.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DUAL-ISOLATE ARCHITECTURE                       │
│                                                                        │
│   [Android OS: Accessibility / ScreenReceiver / ForegroundSvc]         │
│             │                                           │              │
│   kero_space/* channels                       kero_space/bg/* channels │
│             │                                           │              │
│             ▼                                           ▼              │
│   ┌───────────────────────────┐               ┌──────────────────────┐ │
│   │     Main UI Isolate       │               │ Headless BG Isolate  │ │
│   │     (main.dart)           │               │ (backgroundMain())   │ │
│   │  • Flutter Widget Tree    │               │  • IsarService.init()│ │
│   │  • BLoCs & Cubits         │               │  • PII Sanitization  │ │
│   │  • Interactive Dashboard  │               │  • Direct Isar Write │ │
│   └─────────────┬─────────────┘               └──────────┬───────────┘ │
│                 │                                        │             │
│                 ▼                                        ▼             │
│   ┌──────────────────────────────────────────────────────────────────┐ │
│   │                    Shared Isar Database                          │ │
│   │       (ACID / Zero-Copy multi-isolate instance)                  │ │
│   └──────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘
```

The headless entrypoint is declared with `@pragma('vm:entry-point')` in [kero_space_platform_service.dart](file:///c:/projects/Flutter/kero_space/lib/core/data/kero_space_platform_service.dart#L50).

---

## 5. Native Android Daemons & Platform Channels

| Channel | Type | Daemon Component | Purpose |
|---|---|---|---|
| `kero_space/bg/screen_events` | EventChannel | `KeroSpaceScreenReceiver.kt` | Background screen on/off and unlock events |
| `kero_space/bg/accessibility` | EventChannel | `KeroSpaceAccessibilityService.kt` | Real-time click stream & blocker decision audit |
| `kero_space/wake_word` | EventChannel | `WakeWordService.kt` | Neural wake-word trigger & command transcription |
| `kero_space/overlay` | MethodChannel | `OverlayManager.kt` / `CounterOverlayManager.kt` | Fullscreen / floating blocker overlay windows |
| `kero_space/sub_app` | MethodChannel | `SubAppDetector.kt` | Detects in-app reels/shorts activities |
| `kero_space/usage_stats` | MethodChannel | `UsageStatsWorker.kt` | Foreground app usage time queries |
| `kero_space/calendar` | MethodChannel | `CalendarChannelHandler.kt` | Local Android Calendar Provider access |

---

## 6. Docker Backend Specification

### Architecture
- **API Runtime**: Dart Shelf container (`backend/bin/server.dart`)
- **Primary Store**: PostgreSQL 16 (Relational ledger, telemetry archives, encrypted backups)
- **Cache / Queue**: Redis 7 (Sync outbox batches, rate limits)
- **Reverse Proxy**: Caddy 2 (TLS termination with local mTLS certs)

### Sync Protocol
- `POST /sync/batch`: Ingests `SyncOutboxRecord` entities from client.
- `GET /sync/pull?since=<timestamp>`: Returns modified records since last synchronization epoch.
- **Client Outbox Pattern**: Local changes write to Isar first, queue in `syncOutboxRecords`, and dispatch via `SyncWorker`.