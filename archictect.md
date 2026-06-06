# architect.md — Structural Engineering Specification

## 1. High-Level Architecture Overview

ALEF is structured around three concentric layers:

```
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER  (Flutter UI + BLoC State Machines)         │
├─────────────────────────────────────────────────────────────────┤
│  DOMAIN LAYER        (Use Cases, Repositories, Entities)        │
├─────────────────────────────────────────────────────────────────┤
│  DATA LAYER          (Isar Cache ↔ Docker Backend ↔ OS Channels)│
└─────────────────────────────────────────────────────────────────┘
```

The architecture strictly enforces **Dependency Inversion** — the domain layer knows nothing about Flutter, Isar, HTTP, or platform channels. Every external capability is injected via abstract repository interfaces.

---

## 2. BLoC Architecture — Event-Driven State Flow

### Core Pattern
Each feature domain owns exactly one BLoC (or a tree of BLoCs for complex domains). The pattern is strictly:

```
UI Widget
  │  dispatches Event
  ▼
BLoC (Business Logic Component)
  │  calls Repository (abstract interface)
  ▼
Repository Implementation
  │  reads/writes Isar (local) OR HTTP (Docker)
  ▼
Isar / Docker API
  │  emits result
  ▼
BLoC emits State
  │
  ▼
UI Widget rebuilds via BlocBuilder
```

### BLoC Domain Registry

| BLoC | Events | Key States |
|---|---|---|
| `TelemetryBloc` | `AppLaunchDetected`, `ScreenUnlockLogged`, `ClickEventRecorded` | `TelemetryDashboardState(sessions, topApps, unlockTimeline)` |
| `ProductivityBloc` | `TaskCreated`, `TaskCompleted`, `NoteUpdated`, `CalendarSynced` | `TaskListState`, `CalendarViewState` |
| `HealthBloc` | `HealthDataPolled`, `MealLogged`, `CalorieTargetUpdated` | `HealthDashboardState(steps, hr, sleep, macros)` |
| `FinanceBloc` | `InvoiceCreated`, `PaymentReceived`, `EGXPriceRefreshed` | `LedgerState`, `PortfolioState` |
| `ChurchBloc` | `AttendanceMarked`, `ConfessionEntryCreated`, `ServiceTaskUpdated` | `AttendanceStreakState`, `MinistryBoardState` |
| `VoiceBloc` | `WakeWordDetected`, `CommandTranscribed`, `CommandExecuted` | `VoiceIdleState`, `VoiceListeningState`, `CommandResultState` |
| `OverlayBloc` | `BlacklistedAppDetected`, `DecisionBreakExpired`, `AppAccessGranted` | `OverlayInactiveState`, `DecisionBreakState(secondsRemaining)` |

### BLoC Composition Strategy
- `AppBloc` — root navigator + authentication state
- Feature BLoCs are **lazy-initialized** when their route is first accessed
- `TelemetryBloc` and `OverlayBloc` are **always-alive** singletons (initialized at app boot, never disposed)
- Inter-BLoC communication happens via **shared Repository streams**, never direct BLoC-to-BLoC calls

---

## 3. Repository Architecture

### Abstract Interface Pattern
```
abstract class HealthRepository {
  Stream<List<HealthRecord>> watchTodayMetrics();
  Future<void> syncFromHealthConnect();
  Future<void> logMeal(MealEntry meal);
  Future<NutritionalSummary> getDailySummary(DateTime date);
}
```

### Concrete Implementations
Each repository has two implementations, selected by dependency injection:

| Repository | Local Implementation | Remote Implementation |
|---|---|---|
| `HealthRepository` | `IsarHealthRepository` | `DockerHealthRepository` |
| `FinanceRepository` | `IsarFinanceRepository` | `DockerFinanceRepository` |
| `TelemetryRepository` | `IsarTelemetryRepository` | `DockerTelemetryRepository` |
| `ConfessionsRepository` | `EncryptedIsarConfessionsRepo` | *(none — local only)* |
| `CalendarRepository` | `SamsungCalendarChannelRepo` | `GoogleCalendarOAuthRepo` |

The `CompositeRepository` pattern combines local and remote: **writes go to Isar immediately** (optimistic update), then sync to Docker asynchronously. Reads come from Isar first, with a background refresh from Docker.

---

## 4. Isar ↔ Docker Sync Pipeline

### Sync Strategy: Event Sourcing + Conflict Resolution

```
┌────────────────────────────────────────────────────┐
│                  SYNC PIPELINE                     │
│                                                    │
│  User Action                                       │
│      │                                             │
│      ▼                                             │
│  Isar Write (immediate)                            │
│  + Outbox Record {entityId, entityType, operation, │
│                   timestamp, syncStatus: PENDING}  │
│      │                                             │
│      ▼                                             │
│  SyncWorker (background isolate)                   │
│  - Polls outbox every 30s (when network available) │
│  - Batches PENDING records into HTTP PATCH payload │
│  - On success: marks syncStatus = SYNCED           │
│  - On conflict: Last-Write-Wins by default,        │
│                 User-Arbitration for finance data  │
│      │                                             │
│      ▼                                             │
│  Docker Backend                                    │
│  - PostgreSQL primary store                        │
│  - Returns server-side canonical state             │
│      │                                             │
│      ▼                                             │
│  Isar updated with server canonical state          │
└────────────────────────────────────────────────────┘
```

### Isar Schema Design Principles
- Every entity has: `id` (Isar auto-id), `serverId` (UUID from Docker), `syncedAt` (nullable DateTime), `locallyModifiedAt` (DateTime)
- **No foreign keys** — Isar is a document store; relations are modeled as embedded objects or ID references with lazy-loaded queries
- Indexes on: `syncedAt`, `locallyModifiedAt`, `entityType` for efficient outbox queries
- Sensitive collections (`ConfessionEntry`) use `@Collection(accessor: 'confessions')` with a custom encrypted codec

---

## 5. Native Platform Channel Architecture

Flutter communicates with Android/Windows OS capabilities through **MethodChannel** and **EventChannel** bridges. Each bridge is declared as an abstract Dart service interface, with the platform-specific implementation registered on startup.

### Android Platform Channels

| Channel Name | Channel Type | Purpose |
|---|---|---|
| `alef/accessibility` | EventChannel | Streams `AccessibilityEvent` payloads (click coords, package name, view text) from the AccessibilityService |
| `alef/usage_stats` | MethodChannel | Queries `UsageStatsManager` for per-app foreground time by day/week |
| `alef/screen_events` | EventChannel | Streams `Intent.ACTION_SCREEN_ON/OFF`, `ACTION_USER_PRESENT` broadcast events |
| `alef/overlay` | MethodChannel | Commands: `showOverlay(config)`, `dismissOverlay()` — manages `TYPE_APPLICATION_OVERLAY` window |
| `alef/health_connect` | MethodChannel | Reads steps, heart rate, sleep from Health Connect `HealthDataStore` |
| `alef/calendar` | MethodChannel | CRUD on Samsung/Android `CalendarContract` ContentProvider |
| `alef/wake_word` | EventChannel | Streams wake-word detection events from background audio service |

### Windows Platform Channels

| Channel Name | Channel Type | Purpose |
|---|---|---|
| `alef/win_process` | EventChannel | Foreground window title/process tracking via `GetForegroundWindow` Win32 API |
| `alef/win_calendar` | MethodChannel | Outlook/Windows Calendar COM interop (optional) |

### Channel Security Model
- All channels are restricted to the ALEF app's package signature — no external app can invoke them
- AccessibilityService is declared with `android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"` ensuring only the system can bind it

---

## 6. Docker Backend Architecture

### Service Composition (docker-compose.yml)

```
services:
  alef-api:        # Dart Shelf or Rust Actix REST API
  alef-postgres:   # PostgreSQL 16 — primary data store
  alef-redis:      # Redis 7 — sync queue, rate limiting
  alef-caddy:      # Caddy 2 — TLS termination + reverse proxy (local cert)
```

### API Design
- REST with OpenAPI 3.1 spec (auto-generated Dart client via `openapi-generator`)
- JWT-based auth with refresh tokens (the Flutter app authenticates to your own Docker instance)
- All endpoints are `POST /sync/batch` (outbox flush), `GET /sync/pull?since=<timestamp>` (delta pull), plus domain-specific CRUD routes
- TLS required even on LAN — Caddy provisions a self-signed cert trusted by the Android system cert store

### PostgreSQL Schema Strategy
- UUID primary keys everywhere (matches Isar `serverId` field)
- `updated_at` trigger on every table for delta sync
- Row-level encryption on `confessions` table (pgcrypto extension, key derived server-side from user's hashed passphrase — defense-in-depth alongside client-side AES)
- Partitioning on `telemetry_events` by month (high-volume table)

---

## 7. Security Architecture

```
┌─────────────────────────────────────────────────────┐
│  SECURITY LAYERS                                    │
│                                                     │
│  L1: Device Security (Android Keystore / SecureEnclave) │
│      - App signing key, OAuth tokens, JWT stored    │
│        in flutter_secure_storage (hardware-backed)  │
│                                                     │
│  L2: Transport Security (TLS 1.3 + Certificate Pin) │
│      - Dart HTTP client pins Docker server cert     │
│      - Rejects any MITM attempt                     │
│                                                     │
│  L3: Application Encryption (AES-256-GCM)           │
│      - Confessions: client-side before Isar write   │
│      - Key derivation: Argon2id(passphrase, salt)   │
│      - Salt stored separately in Secure Storage     │
│                                                     │
│  L4: Database Encryption (Isar + Postgres)          │
│      - Isar instance opened with encryption key     │
│      - Postgres confessions table: pgcrypto         │
└─────────────────────────────────────────────────────┘
```