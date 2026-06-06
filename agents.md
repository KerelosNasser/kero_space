# Pillar — Agents

> BLoC architecture, event/state contracts, repository pattern, and
> native-bridge contracts. This file is the *how* at the code level.
> Visual concerns live in `design.md`. System concerns live in
> `architecture.md`.

---

## 1. Architectural Style

Pillar uses **BLoC + Repository + UseCase** (the use case layer is
optional; repositories cover most flows).

```mermaid
flowchart LR
  W["Widget"] -->|dispatch Event| B["BLoC"]
  B -->|emit State| W
  B -->|call| R["Repository"]
  R -->|read/write| I[("Isar")]
  R -->|native call| N["PillarPlatform"]
  R -->|sync enqueue| S["SyncEngine"]
  R -->|read/write (financial vault)| C["CryptoEngine"]
  C -->|wrapped DEK| K[("Keystore collection")]
```

### 1.1 Naming conventions

| Element        | Convention                                       | Example                                 |
| -------------- | ------------------------------------------------ | --------------------------------------- |
| Event          | `VerbNounEvent`, past-tense verb                 | `TaskCreated`, `MealLogged`             |
| State          | `FeatureState`, always a sealed class            | `TaskListState`                         |
| State variant  | `Feature` + adjective or `Initial/Loading/...`   | `TaskListLoading`, `TaskListReady`      |
| BLoC           | `FeatureBloc` or `FeatureCubit`                  | `TaskBloc`                              |
| Repository     | `FeatureRepository` (interface) + `...Impl`      | `TaskRepositoryImpl`                    |
| Use case       | `VerbNoun`, one verb, one noun                   | `ComputeMacroTotals`                    |
| Mapper         | `DomainEntityFromXDto`                           | `TaskFromDto`                           |
| Native bridge  | `PillarPlatform`                                 | —                                       |

### 1.2 Folder layout (per pillar)

```
lib/pillars/
  productivity/
    bloc/
      task_bloc.dart
      task_event.dart
      task_state.dart
      notes_bloc.dart
      ...
    data/
      task_repository.dart
      task_dto.dart
      notes_repository.dart
      ...
    domain/
      task.dart           // Isar collection
      note.dart
      ...
    ui/
      task_list_page.dart
      task_detail_page.dart
      ...
```

Cross-pillar code lives in `lib/foundation/`. The Analytics pillar is
*consumer-only*; it never owns a BLoC that writes to other pillars — it
queries their repositories through read-only `Stream` APIs.

---

## 2. Foundation Layer Contracts

### 2.1 `PillarCryptoEngine`

```dart
abstract class PillarCryptoEngine {
  Future<void> unlock(String passphrase);
  Future<void> lock();
  bool get isUnlocked;
  Stream<bool> get lockState; // emits on lock/unlock/auto-relock

  Future<Uint8List> encrypt(Uint8List plaintext, VaultId vault);
  Future<Uint8List> decrypt(Uint8List ciphertext, VaultId vault);

  Future<Uint8List> deriveKey({
    required String info,
    required int length,
  });
}
```

The engine holds the **Master Key** in a `Finalizable` holder. When the
app backgrounds, the holder is zeroed. A `Timer.periodic` (5 min) and a
biometric failure callback call `lock()`.

### 2.2 `PillarPlatform`

Declared in `architecture.md` §7. Each method is `// ignore_for_file:
prefer_const_constructors` annotated because the implementation
differences across platforms.

### 2.3 `PillarSyncEngine`

```dart
abstract class PillarSyncEngine {
  /// Enqueue a single row for sync. Idempotent on (vault, id, version).
  Future<void> enqueue(SyncOp op);

  /// Stream of remote-side changes that have just been applied locally.
  Stream<SyncEvent> get applied;

  /// Stream of conflicts that require manual resolution.
  Stream<SyncConflict> get conflicts;

  /// Force a sync attempt (pulls then pushes). Returns when the queue
  /// drains or the attempt fails.
  Future<SyncReport> syncNow();

  /// The current connectivity + queue depth, for the banner UI.
  Stream<SyncStatusView> get status;
}
```

The sync engine is started exactly once at app boot by `AppShell`. It
owns its own `Isar` collection (`sync_queue`) and a single in-flight
HTTP client (Dio + mTLS interceptor).

### 2.4 `PillarLogger`

```dart
abstract class PillarLogger {
  void trace(String tag, String message, {Map<String, Object?>? ctx});
  void debug(String tag, String message, {Map<String, Object?>? ctx});
  void info(String tag, String message, {Map<String, Object?>? ctx});
  void warn(String tag, String message, {Map<String, Object?>? ctx});
  void error(String tag, String message, {Object error, StackTrace? st});
}
```

The default sink writes to a rotating file in the app documents
directory. A second sink mirrors to Sentry in release builds but only
with `level >= warn` and only with the PII scrubber applied.

---

## 3. Pillar 1 — Omniscient Layer

### 3.1 Domain

```
AppBlacklist         (vault: default, isar collection)
BlacklistEntry       (id, packageId, decisionBreakSeconds, dailyCap, ...)
AppUsage             (id, packageId, startedAt, endedAt, isForeground)
ScreenEvent          (id, ts, type {on, off, unlock})
DeviceEvent          (id, ts, kind {boot, shutdown, chargingOn, chargingOff, headphoneIn, headphoneOut})
WakeWordUtterance    (id, ts, transcript, confidence, action)
FocusSession         (id, startedAt, endedAt, completed)
```

### 3.2 BLoCs

#### `FocusBloc`

State: `FocusState` (sealed)
* `FocusInitial`
* `FocusLoading`
* `FocusReady({blacklist, todayUsage, activeDecisionBreak?})`

Events:
* `FocusSubscribed`
* `BlacklistEntryAdded(BlacklistEntryDraft draft)`
* `BlacklistEntryEdited(String id, BlacklistEntryPatch patch)`
* `BlacklistEntryRemoved(String id)`
* `DecisionBreakRequested(String packageId)`
* `DecisionBreakCompleted(String packageId, IntentNote? note)`
* `DailyCapChanged(String id, Duration cap)`

Side-effects:
* `FocusSubscribed` opens a `StreamSubscription` to
  `PillarPlatform.foregroundAppStream` and recomputes "todayUsage" on
  every tick.
* On `DecisionBreakRequested`, the BLoC pushes a full-screen route
  `DecisionBreakPage(packageId, breakSeconds)` onto the navigator; the
  route uses a `WillPopScope` and a system back-channel on Android to
  prevent dismissal before the timer elapses.
* On `DecisionBreakCompleted`, the BLoC writes a `FocusSession` and an
  optional `IntentNote` (encrypted to `default` vault).

#### `TelemetryIngestBloc`

A **long-lived** BLoC instantiated at app boot. It subscribes to native
streams and persists samples in batches. State is not exposed to the UI
except via a `Stream<TelemetryTick>` that the Analytics pillar consumes.

Events (internal only):
* `AppUsageBatchReceived(List<AppUsage> batch)`
* `ScreenEventBatchReceived(List<ScreenEvent> batch)`
* `DeviceEventBatchReceived(List<DeviceEvent> batch)`
* `WakeWordUtteranceReceived(WakeWordUtterance u)`

Persistence rule: write to Isar in batches of 100 or every 5 s, whichever
comes first. The BLoC is restart-safe: on cold start, it pulls the last
50 samples from each stream to catch up.

#### `WakeWordBloc`

State: `WakeWordState`
* `WakeWordIdle`
* `WakeWordListening({decibels})`
* `WakeWordHeard({utterance, confidence})`
* `WakeWordActionDispatched(AgentAction action)`
* `WakeWordFailed(PillarError error)`

Events:
* `WakeWordEnabled`
* `WakeWordDisabled`
* `WakeWordHotwordDetected({utterance, confidence})`
* `WakeWordActionResolved(AgentAction action)`
* `WakeWordErrored(PillarError error)`

The hotword detection itself lives in the **native service**, not in the
BLoC. The BLoC receives `WakeWordHotwordDetected` via a `BasicMessageChannel`.

The `AgentAction` is resolved by the **AgentRouter** (see §3.3).

### 3.3 AgentRouter

A small in-process registry mapping `(verb, noun)` tuples to BLoC
callbacks. Examples:

| Verb       | Noun          | Action                                               |
| ---------- | ------------- | ---------------------------------------------------- |
| `log`      | `meal`        | `MealBloc.add(MealLoggedFromVoice(...))`             |
| `start`    | `focus`       | `FocusBloc.add(FocusSessionStarted(...))`            |
| `note`     | `idea`        | `NotesBloc.add(NoteCreatedFromVoice(...))`           |
| `read`     | `streak`      | Reads from `StreakRepository.today` and reads aloud   |
| `pay`      | `invoice`     | `InvoiceBloc.add(InvoiceDraftedFromVoice(...))`      |

The router is a pure function `(AgentIntent) → Future<AgentOutcome>`.
It never owns state. Ambiguous intents (low confidence) return
`AgentOutcome.clarify(...)` which the WakeWord surface turns into a
follow-up question on the KeroVoiceSheet.

---

## 4. Pillar 2 — Productivity

### 4.1 Domain

```
Note                 (id, title, bodyMarkdown, tagIds, parentId?, updatedAt, syncVersion)
Tag                  (id, label, color)
Task                 (id, title, description, status, priority, dueAt?, recurrence?, parentId?, blockedByIds, tagIds, updatedAt, syncVersion)
TaskLink             (parentId, childId, kind {subtask, blockedBy, related})
Event                (id, title, description, startAt, endAt, location, source {samsung, google, manual}, externalId?, updatedAt, syncVersion)
EventAttendee        (eventId, name, email?)
```

### 4.2 BLoCs

#### `NotesBloc`

State: `NotesState` (sealed)
* `NotesInitial`
* `NotesLoading`
* `NotesReady({notes, tags, activeTagFilter, query})`
* `NotesError(PillarError)`

Events:
* `NotesSubscribed({String? tagId, String? query})`
* `NoteCreated(NoteDraft draft)`
* `NoteUpdated(NotePatch patch)`
* `NoteDeleted(String id)`
* `NoteMovedToTag(String id, String tagId)`
* `TagCreated(TagDraft draft)`
* `QueryChanged(String q)`

Notes use Isar's `watchLazy` to refresh the list on remote change. The
editor uses a `MarkdownEditor` (custom) backed by `markdown_widget`-style
rendering; we do **not** use a web view.

#### `TaskBloc`

State: `TaskState` (sealed)
* `TaskInitial`
* `TaskLoading`
* `TaskReady({tasks, todayTasks, completedToday, filters})`
* `TaskError(PillarError)`

Events:
* `TaskSubscribed(TaskFilter filter)`
* `TaskCreated(TaskDraft draft)`
* `TaskUpdated(TaskPatch patch)`
* `TaskStatusChanged(String id, TaskStatus status)`
* `TaskRecurrenceAdvanced(String id)` (after completion)
* `TaskDependencyAdded(String id, String blockedById)`
* `TaskDependencyRemoved(String id, String blockedById)`

Task DAG validation lives in the **repository**:
```dart
class TaskCycleError extends PillarError {
  final List<String> cycle;
  TaskCycleError(this.cycle);
}
```
The BLoC surfaces this as a `TaskError(TaskCycleError)` and the UI shows
the cycle visually.

#### `CalendarBloc`

State: `CalendarState` (sealed)
* `CalendarInitial`
* `CalendarLoading
* `CalendarReady({events, sources, conflicts, selectedRange})`
* `CalendarError(PillarError)`

Events:
* `CalendarSubscribed(DateRange range)`
* `RangeChanged(DateRange newRange)`
* `EventCreated(EventDraft draft)`
* `EventUpdated(EventPatch patch)`
* `EventDeleted(String id)`
* `CalendarConflictResolved(String id, ConflictResolution resolution)`
* `SamsungSyncRequested`
* `GoogleSyncRequested`
* `GoogleReauthRequested`

The `CalendarReconciler` background service emits
`CalendarConflictDetected` events into the BLoC. The BLoC owns the
display state; the background service owns the sync state.

#### `GoogleAuthBloc`

State: `GoogleAuthState` (sealed)
* `GoogleAuthUnknown`
* `GoogleAuthSignedOut
* `GoogleAuthSigningIn
* `GoogleAuthSignedIn({email, expiresAt, scopes})
* `GoogleAuthError(PillarError)

Events:
* `GoogleAuthStarted`
* `GoogleAuthSignInRequested
* `GoogleAuthSignOutRequested
* `GoogleAuthRefreshRequested

Tokens are stored via `flutter_secure_storage` (Keystore/DPAPI). Refresh
is automatic and silent; the user only sees a modal on full re-auth.

---

## 5. Pillar 3 — Health & Biometrics

### 5.1 Domain

```
BiometricSample      (id, ts, kind {steps, heartRate, sleepStage, spo2, bodyTemp}, value, unit, source)
Meal                 (id, eatenAt, name, totalKcal, totalProtein, totalCarbs, totalFat, totalFiber, totalWater, items)
MealItem             (id, mealId, ingredientId, grams, computedKcal, computedProtein, computedCarbs, computedFat)
Ingredient           (id, name, category, kcalPer100g, proteinPer100g, carbsPer100g, fatPer100g, fiberPer100g, densityGPerMl?, verified)
Recipe               (id, name, items)
```

### 5.2 BLoCs

#### `HealthIngestBloc`

Subscribes to the `health` package's stream and writes to Isar.
Same batch-write policy as `TelemetryIngestBloc`.

#### `NutritionBloc`

State: `NutritionState` (sealed)
* `NutritionInitial`
* `NutritionLoading
* `NutritionReady({todayMacros, macroTargets, recentMeals, ringFill})
* `NutritionError(PillarError)`

Events:
* `NutritionSubscribed
* `MealLogged(MealDraft draft)
* `IngredientAdded(IngredientDraft draft)
* `MacroTargetsChanged(MacroTargets targets)
* `MealDeleted(String id)
* `RecipeApplied(String recipeId, double servings)

The `MacroRing` widget reads `ringFill` and animates from old → new
over `dur.standard`. The fill is computed by `ComputeMacroTotals`
use case, which is pure and unit-tested.

---

## 6. Pillar 4 — Wealth

### 6.1 Domain

```
Account              (id, name, kind {cash, bank, eWallet, investment, liability}, currency, openingBalance, archived)
JournalEntry         (id, ts, description, sourceInvoiceId?)
JournalLine          (id, journalEntryId, accountId, debit, credit, currency, fxRateToBase)
Invoice              (id, number, clientName, issuedAt, dueAt, status {draft, sent, paid, overdue, void}, lines, currency)
InvoiceLine          (id, invoiceId, description, quantity, unitPrice, vatRate)
Position             (id, symbol, name, sector, currency, openedAt)
Lot                  (id, positionId, acquiredAt, quantity, unitPrice, fees, fxRateToBase)
PriceTick            (id, symbol, ts, price, currency, source {egx, manual})
Dividend             (id, positionId, paidAt, grossAmount, withholding, currency, fxRateToBase)
FxRate               (id, baseCcy, quoteCcy, ts, rate)
```

### 6.2 BLoCs

#### `LedgerBloc`

State: `LedgerState` (sealed)
* `LedgerInitial`
* `LedgerLoading
* `LedgerReady({accounts, journal, balanceSheet, incomeStatement, filters})
* `LedgerError(PillarError)

Events:
* `LedgerSubscribed(DateRange range)
* `AccountCreated(AccountDraft)
* `AccountUpdated(AccountPatch)
* `JournalEntryCreated(JournalEntryDraft) // server-validated for Σ debits == Σ credits
* `InvoiceCreated(InvoiceDraft)
* `InvoiceStatusChanged(String id, InvoiceStatus)
* `PaymentReceived(String invoiceId, JournalLineDraft)

`Σ debits == Σ credits` is enforced in the repository's
`createJournalEntry`. The BLoC surfaces a `LedgerError(ImbalanceError)`
with the precise delta. The amount is always stored in the base
currency (EGP by default) **and** the original currency, with the FX
rate stamped at entry time — historical FX rates are never re-evaluated.

#### `EgxBloc`

State: `EgxState` (sealed)
* `EgxInitial`
* `EgxLoading
* `EgxReady({positions, performance, allocation, dividendYield, lastTickAt, isStale})
* `EgxError(PillarError)

Events:
* `EgxSubscribed
* `PositionAdded(PositionDraft)
* `LotAdded(String positionId, LotDraft)
* `LotDisposed(String positionId, DisposalDraft)
* `ManualPriceTickRecorded(String symbol, double price, DateTime ts)
* `EgxRefreshRequested

`EgxRefreshRequested` triggers a `WorkManager` job that hits the Dock
proxy, which in turn scrapes EGX public feeds. The Dock **never** sees
the user's positions or quantities — it returns a `Map<symbol,
PriceTick>` keyed only by symbol.

The P&L calculator:
* **Realised P&L** = Σ (disposal.unitPrice - lot.unitPrice) × qty × fx
* **Unrealised P&L** = (latestTick.price - avgCost) × openQty × fx
* **Dividend yield** = Σ(rolling 12m gross dividends) / current MV

---

## 7. Pillar 5 — Spiritual

### 7.1 Domain

```
Confession           (id, ts, bodyEncrypted, moodBefore?, moodAfter?, scriptureRefs?)
MinistryMember       (id, name, contact, role, notesEncrypted?, tags, archivedAt?)
MinistryTask         (id, memberId?, title, description, status, dueAt, recurrence)
MassAttendance       (id, ts, kind {sunday, feast, weekday, special}, note?)
Streak               (id, kind, title, startedAt, currentCount, longestCount, graceDays)
StreakDay            (streakId, date, status {kept, missed, exempt, future})
ScriptureRef         (id, book, chapter, verseStart, verseEnd?)
```

All collections in this pillar are stored in the **`spiritual` vault**.
The BLoC layer never sees plaintext bodies — it only ever receives
already-decrypted data, and only while the `Keyring` is unlocked.

### 7.2 BLoCs

#### `ConfessionalBloc`

State: `ConfessionalState` (sealed)
* `ConfessionalInitial`
* `ConfessionalLocked
* `ConfessionalUnlocked({entries, activeDraft})
* `ConfessionalError(PillarError)

Events:
* `ConfessionalUnlockRequested(String passphrase)
* `ConfessionalLockRequested
* `ConfessionalEntryCreated(ConfessionDraft)
* `ConfessionalEntryUpdated(String id, ConfessionPatch)
* `ConfessionalEntryDeleted(String id)
* `ConfessionalSearched(String query)  // client-side FTS

The BLoC **must** be instantiated only after the `Keyring` is unlocked.
A `BlocObserver` in the foundation layer asserts this on creation.

#### `MinistryBloc`

State: `MinistryState` (sealed)
* `MinistryInitial`
* `MinistryLoading
* `MinistryReady({members, tasks, kanban})
* `MinistryError(PillarError)

Events:
* `MinistrySubscribed
* `MemberAdded(MemberDraft)
* `MemberUpdated(MemberPatch)
* `TaskCreated(MinistryTaskDraft)
* `TaskStatusChanged(String id, MinistryTaskStatus)
* `MemberArchived(String id)

The kanban view groups tasks by status; members are filter chips.

#### `StreaksBloc`

State: `StreaksState` (sealed)
* `StreaksInitial`
* `StreaksLoading
* `StreaksReady({streaks, gridRange, todayStatus})
* `StreaksError(PillarError)

Events:
* `StreaksSubscribed
* `StreakDefined(StreakDraft)        // user creates a habit loop
* `StreakDayChecked(String streakId, DateTime date)
* `StreakDayUnchecked(String streakId, DateTime date)
* `StreakGraceApplied(String streakId, DateTime date, int grace)

`StreakDayChecked` is **also** emitted by `MassAttendanceRecorded` and
by the WakeWordAgent's `log mass` intent, so the BLoC must be idempotent
on `(streakId, date)`.

---

## 8. Pillar 6 — Analytics

### 8.1 Domain

The Analytics pillar owns **no collections**. It reads from every other
pillar's read-only repository streams and produces derived views in
memory.

```
InsightCard          (id, kind, title, body, primaryMetric, secondaryMetric, relatedStreams)
CorrelationPoint     (xMetric, yMetric, x, y, ts)
```

### 8.2 BLoCs

#### `InsightsBloc`

State: `InsightsState` (sealed)
* `InsightsInitial`
* `InsightsLoading
* `InsightsReady({cards, scatter, weekRange, scatterX, scatterY})
* `InsightsError(PillarError)

Events:
* `InsightsSubscribed(DateRange range)
* `RangeChanged(DateRange newRange)
* `ScatterAxesChanged(ScatterMetric x, ScatterMetric y)

The BLoC is the only place where cross-pillar correlation is computed.
The `CorrelationEngine` use case runs in a `compute()` isolate to keep
the UI thread free.

---

## 9. Cross-cutting Patterns

### 9.1 Error model

```dart
sealed class PillarError {
  String get code;
  String get userMessage; // localized
  String get developerMessage;
  Object? get cause;
}
```

Every BLoC `State` variant that represents an error carries a
`PillarError`. UI maps the code to one of:
* `KeroToast` for transient errors (network, sync).
* `KeroErrorState` for full-screen errors (DB corruption, key lost).
* `KeroDialog` for actionable errors (auth, permission revoked).

### 9.2 Loading

Three flavours, in order of preference:
1. **Inline** (`KeroSkeleton` of the same shape as the final widget).
2. **Section-level** (`KeroCard` with a centred spinner — only for
   unpredictable loads).
3. **Full-screen** (`KeroScaffold` with a single `CircularProgress` — only
   on cold start or when the `Keyring` is being unlocked).

### 9.3 Pagination

* All list BLoCs use a `Pagination` mixin that exposes
  `loadMore()`, `hasMore`, `isLoadingMore`.
* Underlying Isar queries use a `limit`+`offset`; the repository
  internally memoises the last cursor.
* The UI uses a `NotificationListener` on the scroll view to trigger
  `loadMore` when within 200 dp of the end.

### 9.4 Optimistic updates

Default for any single-row mutation (toggle, archive, complete). The BLoC:
1. Emits the new state immediately.
2. Calls the repository.
3. On success, no change to state (the Isar watcher will fire and
   re-emit a normalized state).
4. On error, **rolls back** the state and emits a `KeroToast` with
   "Undone: <human action>".

### 9.5 Background-aware BLoCs

BLoCs that hold long-lived subscriptions (Telemetry, Health, Sync) are
listed in a `BLoCRegistry` and re-subscribed when the app returns to
foreground. The `LifecycleObserver` in the foundation layer owns this.

### 9.6 Test strategy

* **Unit** — every repository, every use case, every mapper, every
  encryption helper. `bloc_test` covers BLoC event→state transitions
  with mocked repositories.
* **Widget** — every screen with golden tests in dark, light, RTL, and
  reduced-motion. `patrol` for native integration tests on Android.
* **Integration** — Patrol scenarios for the Decision Break end-to-end
  and the Confessional encrypt/decrypt round trip.
* **Property** — `fast_check` on the ledger invariants (Σ debits ==
  Σ credits) and the streak invariants (no future days kept).

---

## 10. Repository Pattern (reference)

```dart
abstract class TaskRepository {
  Stream<List<Task>> watch(TaskFilter filter);
  Future<Task> get(String id);
  Future<void> create(TaskDraft draft);
  Future<void> update(String id, TaskPatch patch);
  Future<void> delete(String id);
  Future<void> setStatus(String id, TaskStatus status);

  /// Atomic across local + sync. Throws [PillarError] on any failure.
  Future<JournalEntry> postCompletionToLedger(String taskId);
}
```

Every repository follows this shape:
* **Reads** return `Stream`s backed by Isar's `watchLazy`.
* **Writes** are atomic within a single `isar.writeTxn`; multi-collection
  writes wrap a `isar.writeTxn` around the whole operation.
* **Errors** are translated to `PillarError` before bubbling up.
* **No BLoC** ever imports `package:isar/isar.dart` directly.

---

## 11. The Agent Registry (final form)

```dart
abstract class AgentRouter {
  Future<AgentOutcome> dispatch(AgentIntent intent);
  Stream<AgentIntent> get ambientIntents; // from WakeWord, NFC, etc.
}
```

The router is the **only** place where cross-pillar BLoCs are
coordinated. There is no global event bus; intents are typed and
exhaustive (`sealed class AgentIntent`).

---

*End of agents.md. See `tasks.md` for the build order and acceptance
criteria.*
