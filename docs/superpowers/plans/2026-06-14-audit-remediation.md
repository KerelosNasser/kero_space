# Kero Space Audit Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all 80 audit issues across Kotlin and Flutter codebases, prioritized by severity (P0 ship-blockers → P1 critical quality → P2 design system → P3 spec completeness)

**Architecture:** Fix issues per-file with minimal cross-file impact. Kotlin fixes target 11 native files. Flutter fixes target BLoCs, screens, DI, and platform service. Each task is scoped to ≤2 hours per AGENTS.md Small-Task Constraint.

**Tech Stack:** Flutter 3.x / Dart 3.x with BLoC, Kotlin 1.9+ with coroutines/WorkManager, Isar DB, go_router, GetIt

---

## File Structure

### Kotlin Files Modified
- `android/app/src/main/kotlin/com/example/kero_space/WakeWordService.kt` — Remove mock trigger, fix startForeground, fix JSON injection
- `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceForegroundService.kt` — Fix startService→startForegroundService, add RECEIVER_NOT_EXPORTED, fix onTimeout
- `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceAccessibilityService.kt` — Implement full PII sanitization
- `android/app/src/main/kotlin/com/example/kero_space/UsageStatsWorker.kt` — Scope broadcast, add constraints
- `android/app/src/main/kotlin/com/example/kero_space/OverlayManager.kt` — Fix race condition
- `android/app/src/main/kotlin/com/example/kero_space/MainActivity.kt` — Add input validation
- `android/app/src/main/kotlin/com/example/kero_space/AgentManager.kt` — Fix ANR issues, fix deprecated API
- `android/app/src/main/kotlin/com/example/kero_space/CalendarChannelHandler.kt` — Move off main thread
- `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceScreenReceiver.kt` — Add session duration computation
- `android/app/src/main/kotlin/com/example/kero_space/BlacklistPreferencesStore.kt` — Fix race condition

### Dart Files Modified
- `pubspec.yaml` — Remove unused speech_to_text dependency
- `lib/core/data/kero_space_platform_service.dart` — Add PII sanitization in background isolate
- `lib/core/data/isar_service.dart` — Guard init race condition
- `lib/core/di/injection.dart` — No changes (singleton pattern is by design for app-scoped BLoCs)
- `lib/features/voice/presentation/bloc/voice_bloc.dart` — Fix cross-BLoC coupling, handle NavigateIntent/BlockAppIntent, fix fallback trigger
- `lib/features/voice/presentation/bloc/voice_state.dart` — Remove SecretKey from props
- `lib/features/voice/domain/command_parser.dart` — Cache regexes, fix decimal validation
- `lib/features/church/presentation/bloc/confession_bloc.dart` — Remove passphrase from Equatable props
- `lib/features/health/presentation/bloc/health_bloc.dart` — Add try/catch, fix copyWith null bug
- `lib/features/finance/presentation/bloc/finance_bloc.dart` — Fix N+1 HTTP, remove NutritionRepository coupling, fix double iteration
- `lib/features/finance/presentation/bloc/finance_event.dart` — Fix props type
- `lib/features/productivity/presentation/bloc/productivity_bloc.dart` — Fix firstWhere, reduce reloads, remove stack trace leakage
- `lib/features/productivity/presentation/bloc/calendar_bloc.dart` — Move Coptic computation to isolate, fix list mutation, fix caching
- `lib/features/telemetry/presentation/bloc/telemetry_bloc.dart` — Add try/catch, debounce Isar watch, populate blocker stats
- `lib/features/church/presentation/bloc/church_bloc.dart` — Fix copyWith null bug
- `lib/features/settings/presentation/screens/settings_screen.dart` — Dispose controller
- `lib/features/church/presentation/screens/confession_log_screen.dart` — Dispose controller, fix Colors
- `lib/features/health/presentation/screens/meal_log_screen.dart` — Fix controller lifecycle, fix Colors
- `lib/features/church/presentation/screens/ministry_kanban_screen.dart` — Fix all hardcoded Colors
- `lib/features/church/presentation/screens/attendance_screen.dart` — Fix all hardcoded Colors
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — Fix hardcoded Colors
- `lib/features/productivity/presentation/screens/productivity_screen.dart` — Fix hardcoded Colors
- `lib/features/productivity/presentation/widgets/daily_checklist.dart` — Fix hardcoded Colors
- `lib/features/productivity/presentation/widgets/task_tree_view.dart` — Fix hardcoded Colors
- `lib/features/voice/presentation/widgets/voice_bottom_sheet.dart` — Fix hardcoded Colors
- `lib/features/voice/presentation/widgets/voice_waveform.dart` — Fix hardcoded Colors
- `lib/features/voice/presentation/widgets/command_hint_ticker.dart` — Fix hardcoded Colors
- `lib/features/home/presentation/screens/home_screen.dart` — Fix Colors.transparent
- `lib/features/telemetry/presentation/pages/telemetry_screen.dart` — Fix Colors.transparent
- `lib/features/health/presentation/screens/ingredient_search_screen.dart` — Fix Colors, remove mock FAB
- `lib/features/health/presentation/screens/calorie_config_screen.dart` — Add form validators
- `lib/core/error/error_snackbar_listener.dart` — Fix hardcoded Colors
- `lib/core/permissions/permission_banner.dart` — Fix touch target, fix Colors
- `lib/features/confession_auth_screen.dart` — Fix Colors
- `lib/features/finance/presentation/widgets/career_tab.dart` — Fix TODO string constants

---

## P0: SHIP BLOCKERS (8 tasks)

### Task 1: Fix WakeWordService ADB Mock + startForeground + JSON Injection

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/WakeWordService.kt`

**Requirements:**
1. Gate `mockTriggerReceiver` behind `BuildConfig.DEBUG` — remove from release builds entirely
2. Add `RECEIVER_NOT_EXPORTED` on ALL API levels (use `ContextCompat.registerReceiver` or explicit flag check)
3. Call `startForeground()` with a notification within 5 seconds of `onStartCommand()`
4. Fix `emitWakeWordEvent` JSON injection — use `JSONObject.put()` instead of string interpolation
5. Ensure `onDestroy()` properly releases `AudioRecord` and stops the handler thread

- [ ] **Step 1:** Read current `WakeWordService.kt`
- [ ] **Step 2:** Replace mock trigger registration with `if (BuildConfig.DEBUG)` guard, use `RECEIVER_NOT_EXPORTED` on all API levels
- [ ] **Step 3:** Add `startForeground()` call in `onStartCommand()` with a notification channel and notification builder
- [ ] **Step 4:** Replace JSON string interpolation in `emitWakeWordEvent` with `JSONObject` builder
- [ ] **Step 5:** Ensure `onDestroy()` calls `audioRecord?.stop()` then `audioRecord?.release()`, then `handlerThread?.quit()`
- [ ] **Step 6:** Verify no compilation errors by reading the final file
- [ ] **Step 7:** Commit

### Task 2: Fix KeroSpaceForegroundService — startForegroundService + RECEIVER_NOT_EXPORTED + onTimeout

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceForegroundService.kt`

**Requirements:**
1. Change `startService(Intent(this, WakeWordService::class.java))` to `startForegroundService()`
2. Add `RECEIVER_NOT_EXPORTED` flag to pre-TIRAMISU custom action receiver registrations (`usageStatsReceiver`)
3. Fix `onTimeout` to reschedule the service instead of just stopping it
4. Move `startFlutterEngine()` I/O off main thread using a coroutine

- [ ] **Step 1:** Read current `KeroSpaceForegroundService.kt`
- [ ] **Step 2:** Replace `startService()` with `startForegroundService()` for WakeWordService on line 85
- [ ] **Step 3:** Add `RECEIVER_NOT_EXPORTED` flag usage for `usageStatsReceiver` on all API levels
- [ ] **Step 4:** In `onTimeout`, schedule a restart via AlarmManager before stopping self
- [ ] **Step 5:** Wrap `startFlutterEngine()` calls in `CoroutineScope(Dispatchers.IO).launch`
- [ ] **Step 6:** Verify no compilation errors
- [ ] **Step 7:** Commit

### Task 3: Implement Full PII Sanitization in AccessibilityService

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceAccessibilityService.kt`

**Requirements:**
1. Add `sanitizeText()` function that redacts: passwords/PIN (viewId check), 16-digit card numbers (regex), email patterns in login contexts
2. Apply sanitization before forwarding any click event data
3. Add `clickX`/`clickY` coordinates from `event.source?.getBoundsInScreen()`
4. Remove `typeViewTextChanged` from accessibility config XML or add a handler

- [ ] **Step 1:** Read current `KeroSpaceAccessibilityService.kt` and `android/app/src/main/res/xml/accessibility_service_config.xml`
- [ ] **Step 2:** Add `sanitizeText()` private function with card number regex, email regex, password field detection
- [ ] **Step 3:** Add click coordinate extraction from `event.source?.getBoundsInScreen()`
- [ ] **Step 4:** Apply `sanitizeText()` to any text data before JSON emission
- [ ] **Step 5:** Either remove `typeViewTextChanged` from config XML or add a handler in the `when` block
- [ ] **Step 6:** Verify no compilation errors
- [ ] **Step 7:** Commit

### Task 4: Scope UsageStatsWorker Broadcast + Add WorkManager Constraints

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/UsageStatsWorker.kt`
- Modify: `android/app/src/main/kotlin/com/example/kero_space/AgentManager.kt`

**Requirements:**
1. Add `intent.setPackage(packageName)` to `USAGE_STATS_READY` broadcast to prevent PII leak
2. Add `Constraints` to WorkManager PeriodicWorkRequest: `setRequiresBatteryNotLow(true)`, `setRequiredNetworkType(NetworkType.NOT_REQUIRED)`
3. Add null-check on `getSystemService()` cast

- [ ] **Step 1:** Read current `UsageStatsWorker.kt` and `AgentManager.kt`
- [ ] **Step 2:** Add `intent.setPackage(applicationContext.packageName)` before `sendBroadcast()`
- [ ] **Step 3:** In `AgentManager.kt`, add `Constraints.Builder()` with battery and network constraints to the PeriodicWorkRequest
- [ ] **Step 4:** Add null safety check on `getSystemService(USAGE_STATS_SERVICE)` cast
- [ ] **Step 5:** Verify no compilation errors
- [ ] **Step 6:** Commit

### Task 5: Fix OverlayManager Race Condition

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/OverlayManager.kt`

**Requirements:**
1. Replace `@Volatile var overlayShowing` with `AtomicBoolean` and use `compareAndSet()` for atomic check-then-act

- [ ] **Step 1:** Read current `OverlayManager.kt`
- [ ] **Step 2:** Replace `@Volatile var overlayShowing = false` with `val overlayShowing = AtomicBoolean(false)`
- [ ] **Step 3:** Replace `if (overlayShowing) return` with `if (!overlayShowing.compareAndSet(false, true)) return`
- [ ] **Step 4:** Set `overlayShowing.set(false)` in dismiss
- [ ] **Step 5:** Verify no compilation errors
- [ ] **Step 6:** Commit

### Task 6: Fix AgentManager ANR + Deprecated API

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/AgentManager.kt`

**Requirements:**
1. Replace `getWorkInfosForUniqueWork().get()` with asynchronous `FutureCallback` or `suspendCancellableCoroutine`
2. Replace deprecated `getRunningServices()` with static `isRunning` flag pattern in each service
3. Fix `startService()` to `startForegroundService()` for WakeWordService toggle

- [ ] **Step 1:** Read current `AgentManager.kt`
- [ ] **Step 2:** Replace blocking `get()` with coroutine-based approach using `await()` on ListenableFuture
- [ ] **Step 3:** Add companion `isRunning` flag in WakeWordService, set true/false in onStart/onDestroy, read from AgentManager
- [ ] **Step 4:** Replace `getRunningServices()` with the static flag check
- [ ] **Step 5:** Change `context.startService(wakeIntent)` to `context.startForegroundService(wakeIntent)`
- [ ] **Step 6:** Verify no compilation errors
- [ ] **Step 7:** Commit

### Task 7: Add PII Sanitization in Flutter Background Isolate

**Files:**
- Modify: `lib/core/data/kero_space_platform_service.dart`

**Requirements:**
1. Add `sanitizeClickData()` function matching the Kotlin-side sanitization: strip passwords, card numbers, emails from raw JSON before Isar write
2. Apply sanitization before storing `dataJson` field in the accessibility listener
3. Remove unused `speech_to_text` from `pubspec.yaml`

- [ ] **Step 1:** Read current `kero_space_platform_service.dart` and `pubspec.yaml`
- [ ] **Step 2:** Add `String _sanitizeClickJson(String raw)` function that decodes JSON, redacts PII patterns, re-encodes
- [ ] **Step 3:** Apply `_sanitizeClickJson(raw)` before `dataJson: raw` assignment on line 67
- [ ] **Step 4:** Remove `speech_to_text: ^7.4.0` line from `pubspec.yaml`
- [ ] **Step 5:** Run `flutter analyze` to verify no issues
- [ ] **Step 6:** Commit

### Task 8: Fix CalendarChannelHandler ANR — Move Off Main Thread

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/CalendarChannelHandler.kt`

**Requirements:**
1. Move `contentResolver.query()` off main thread using `CoroutineScope(Dispatchers.IO)`
2. Add column index validation before `getString()` calls
3. Return results via `Result.success()` after the coroutine completes

- [ ] **Step 1:** Read current `CalendarChannelHandler.kt`
- [ ] **Step 2:** Wrap contentResolver.query in `CoroutineScope(Dispatchers.IO).launch` and return result via channel
- [ ] **Step 3:** Validate `getColumnIndex()` returns > -1 before using column indices
- [ ] **Step 4:** Verify no compilation errors
- [ ] **Step 5:** Commit

---

## P1: CRITICAL QUALITY (9 tasks)

### Task 9: Fix VoiceBloc — Cross-BLoC Coupling + Missing Intent Handlers + Fallback Trigger

**Files:**
- Modify: `lib/features/voice/presentation/bloc/voice_bloc.dart`
- Modify: `lib/features/voice/presentation/bloc/voice_state.dart`

**Requirements:**
1. Replace direct BLoC references with an event bus or command dispatch via `GetIt` + stream
2. Handle `NavigateIntent` → call `router.go(intent.route)` via a navigation service
3. Handle `BlockAppIntent` → call `KeroSpacePlatformService.setBlacklistRules()`
4. Fix `jsonDecode` fallback: emit `VoiceError` instead of `WakeWordTriggered()` on malformed data
5. Remove `SecretKey` from `VoiceWakeDetected` props in `voice_state.dart`

- [ ] **Step 1:** Read current `voice_bloc.dart`, `voice_state.dart`, `voice_event.dart`
- [ ] **Step 2:** Create a `VoiceCommandDispatcher` that dispatches commands without direct BLoC references — use `GetIt` to lazily resolve targets
- [ ] **Step 3:** Add handlers for `NavigateIntent` and `BlockAppIntent` in `_onConfirmIntent`
- [ ] **Step 4:** Change malformed JSON fallback from `WakeWordTriggered()` to `VoiceError('Invalid wake data')`
- [ ] **Step 5:** Remove `SecretKey` from Equatable `props` in voice states
- [ ] **Step 6:** Run `flutter analyze`
- [ ] **Step 7:** Commit

### Task 10: Fix ConfessionBloc — Remove Passphrase/SecretKey from Equatable Props

**Files:**
- Modify: `lib/features/church/presentation/bloc/confession_bloc.dart`

**Requirements:**
1. Remove `passphrase` from `UnlockConfessionSession.props` — use `[]` or `[identity]`
2. Remove `passphrase` from `EnableBiometrics.props`
3. Remove `SecretKey` from `ConfessionUnlocked.props`

- [ ] **Step 1:** Read current `confession_bloc.dart`
- [ ] **Step 2:** Change `UnlockConfessionSession` props to exclude passphrase
- [ ] **Step 3:** Change `EnableBiometrics` props to exclude passphrase
- [ ] **Step 4:** Change `ConfessionUnlocked` props to `[]`
- [ ] **Step 5:** Run `flutter analyze`
- [ ] **Step 6:** Commit

### Task 11: Fix HealthBloc — Add try/catch + Fix copyWith Null Bug

**Files:**
- Modify: `lib/features/health/presentation/bloc/health_bloc.dart`

**Requirements:**
1. Add try/catch in `_onLogMeal` — emit error state on failure
2. Add try/catch in `_onToggleFastingMode` — emit error state on failure
3. Fix `copyWith` null bug for `errorMessage` — use `Object?` wrapper pattern or `clearError` boolean
4. Add fire-and-forget error handling for `syncBiometrics()`

- [ ] **Step 1:** Read current `health_bloc.dart`
- [ ] **Step 2:** Wrap `_onLogMeal` body in try/catch, emit error state on catch
- [ ] **Step 3:** Wrap `_onToggleFastingMode` body in try/catch, emit error state on catch
- [ ] **Step 4:** Fix `copyWith` to allow clearing `errorMessage` — use optional parameter `bool? clearError`
- [ ] **Step 5:** Wrap `syncBiometrics()` call in try/catch with `debugPrint` for error
- [ ] **Step 6:** Run `flutter analyze`
- [ ] **Step 7:** Commit

### Task 12: Fix FinanceBloc — N+1 HTTP + Cross-Domain Coupling + Double Iteration

**Files:**
- Modify: `lib/features/finance/presentation/bloc/finance_bloc.dart`
- Modify: `lib/features/finance/presentation/bloc/finance_event.dart`
- Modify: `lib/features/finance/presentation/bloc/finance_state.dart`
- Modify: `lib/core/di/injection.dart`

**Requirements:**
1. Convert sequential stock price fetches to parallel using `Future.wait()`
2. Remove `NutritionRepository` dependency — accept nutrition correlation data as an event payload instead
3. Fix double iteration — single-pass accumulation for date-keyed totals
4. Fix `List<Object>` → `List<Object?>` in event/state props

- [ ] **Step 1:** Read current `finance_bloc.dart`, `finance_event.dart`, `finance_state.dart`, `injection.dart`
- [ ] **Step 2:** Replace sequential stock fetches with `await Future.wait(watchlist.map(...))`
- [ ] **Step 3:** Remove `NutritionRepository` from constructor, remove from DI registration
- [ ] **Step 4:** Replace double iteration with single-pass date-keyed accumulation using `fold()`
- [ ] **Step 5:** Fix `List<Object>` → `List<Object?>` in event/state props
- [ ] **Step 6:** Run `flutter analyze`
- [ ] **Step 7:** Commit

### Task 13: Fix ProductivityBloc — firstWhere + Reload Spam + Stack Trace Leakage

**Files:**
- Modify: `lib/features/productivity/presentation/bloc/productivity_bloc.dart`

**Requirements:**
1. Add `orElse` to `firstWhere` call
2. Replace `add(LoadData())` spam with targeted state updates for create/delete/toggle operations
3. Replace raw `$e` interpolation with generic error messages in all catch blocks

- [ ] **Step 1:** Read current `productivity_bloc.dart`
- [ ] **Step 2:** Add `orElse: () => Task()..id = -1` or similar guard, handle the not-found case
- [ ] **Step 3:** Replace `add(LoadData())` after mutations with direct emit of updated state from current state + mutation result
- [ ] **Step 4:** Replace all `$e` error interpolations with generic user-facing messages like `'Failed to save. Please try again.'`
- [ ] **Step 5:** Run `flutter analyze`
- [ ] **Step 6:** Commit

### Task 14: Fix CalendarBloc — Move Coptic Computation to Isolate + Fix List Mutation + Fix Caching

**Files:**
- Modify: `lib/features/productivity/presentation/bloc/calendar_bloc.dart`

**Requirements:**
1. Move Coptic computus to `compute()` isolate
2. Fix `events.addAll(_cachedCopticEvents!)` — create a new list instead of mutating the returned one
3. Make `_cachedCopticEvents` properly scoped with clearing on BLoC re-creation

- [ ] **Step 1:** Read current `calendar_bloc.dart`
- [ ] **Step 2:** Extract Coptic computus into a top-level function and call via `await compute(_computeCopticEvents, yearRange)`
- [ ] **Step 3:** Replace `events.addAll()` with `[...events, ..._cachedCopticEvents!]`
- [ ] **Step 4:** Ensure `_cachedCopticEvents` is cleared properly via a reset method
- [ ] **Step 5:** Run `flutter analyze`
- [ ] **Step 6:** Commit

### Task 15: Fix TelemetryBloc — Add try/catch + Debounce Isar Watch + Populate Blocker Stats

**Files:**
- Modify: `lib/features/telemetry/presentation/bloc/telemetry_bloc.dart`

**Requirements:**
1. Add try/catch to `_onLoadBlacklist`, `_onAddRule`, `_onRemoveRule`, `_onUpdateRule`
2. Add try/catch to `_onToggleAgent`, `_onRefreshStatuses`
3. Debounce Isar watch subscriptions — use `restartable()` transformer or add 500ms debounce
4. Populate `_onLoadBlockerStats` with actual data instead of empty list

- [ ] **Step 1:** Read current `telemetry_bloc.dart`
- [ ] **Step 2:** Wrap all event handlers in try/catch, emit error states
- [ ] **Step 3:** Add debounce transformer: `on<LoadTelemetryDashboard>(_onLoad, transformer: restartable())`
- [ ] **Step 4:** Implement `_onLoadBlockerStats` with real Isar queries for overlay event counts
- [ ] **Step 5:** Run `flutter analyze`
- [ ] **Step 6:** Commit

### Task 16: Fix ChurchBloc copyWith Null Bug

**Files:**
- Modify: `lib/features/church/presentation/bloc/church_bloc.dart`

**Requirements:**
1. Fix `copyWith` for `errorMessage` — use `bool? clearError` pattern to allow nulling the error on success

- [ ] **Step 1:** Read current `church_bloc.dart`
- [ ] **Step 2:** Add `bool clearError = false` parameter to `copyWith`, implement: `errorMessage: clearError ? null : (errorMessage ?? this.errorMessage)`
- [ ] **Step 3:** Use `clearError: true` in success emits
- [ ] **Step 4:** Run `flutter analyze`
- [ ] **Step 5:** Commit

### Task 17: Fix Widget Memory Leaks (3 Controllers)

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/features/church/presentation/screens/confession_log_screen.dart`
- Modify: `lib/features/health/presentation/screens/meal_log_screen.dart`

**Requirements:**
1. Dispose `_dockerUrlController` in `settings_screen.dart`
2. Dispose `_controller` (QuillController) in `confession_log_screen.dart`
3. Move `TextEditingController` from `build()` to state field in `meal_log_screen.dart`, dispose in `dispose()`

- [ ] **Step 1:** Read all 3 files
- [ ] **Step 2:** Add `dispose()` method to `SettingsScreen` state that calls `_dockerUrlController.dispose()`
- [ ] **Step 3:** Add `dispose()` method to `ConfessionLogScreen` state that calls `_controller.dispose()`
- [ ] **Step 4:** In `MealLogScreen`, move `TextEditingController` from `build()` to `initState()`, add `dispose()`
- [ ] **Step 5:** Run `flutter analyze`
- [ ] **Step 6:** Commit

---

## P2: DESIGN SYSTEM COMPLIANCE (6 tasks)

### Task 18: Fix Hardcoded Colors — Church Screens

**Files:**
- Modify: `lib/features/church/presentation/screens/ministry_kanban_screen.dart`
- Modify: `lib/features/church/presentation/screens/attendance_screen.dart`
- Modify: `lib/features/church/presentation/screens/confession_log_screen.dart`
- Modify: `lib/features/church/presentation/screens/confession_auth_screen.dart`

**Requirements:**
1. Replace ALL `Colors.black` → `AppTheme.bgPrimary`
2. Replace ALL `Colors.white` → `AppTheme.textPrimary` or `AppTheme.accentPrimary`
3. Replace ALL `Colors.grey` / `Colors.grey.withAlpha(128)` → `AppTheme.textSecondary` or `AppTheme.textDisabled`
4. Replace ALL `Colors.red` → `AppTheme.accentRose`
5. Replace ALL raw `Color(0xFFBF5AF2)` → `AppTheme.accentViolet`
6. Replace ALL raw `Color(0xFF1C1C1E)` → `AppTheme.bgSurface`
7. Replace ALL raw `Color(0xFF2C2C2E)` → `AppTheme.bgElevated`
8. Add `import '../../core/app_theme.dart'` (via `package:kero_space/core/app_theme.dart`) where needed

- [ ] **Step 1:** Read all 4 files
- [ ] **Step 2-5:** Fix each file systematically
- [ ] **Step 6:** Run `flutter analyze`
- [ ] **Step 7:** Commit

### Task 19: Fix Hardcoded Colors — Productivity + Health + Home Screens

**Files:**
- Modify: `lib/features/productivity/presentation/screens/productivity_screen.dart`
- Modify: `lib/features/productivity/presentation/widgets/daily_checklist.dart`
- Modify: `lib/features/productivity/presentation/widgets/task_tree_view.dart`
- Modify: `lib/features/health/presentation/screens/meal_log_screen.dart`
- Modify: `lib/features/health/presentation/screens/ingredient_search_screen.dart`
- Modify: `lib/features/home/presentation/screens/home_screen.dart`

**Requirements:**
1. `Colors.purple` → `AppTheme.accentViolet`
2. `Colors.blue` → `AppTheme.accentCyan`
3. `Colors.green` → `AppTheme.accentMint`
4. `Colors.red` → `AppTheme.accentRose`
5. `Colors.orange` → `AppTheme.accentGold`
6. `Colors.white` → `AppTheme.textPrimary` or `AppTheme.accentPrimary`
7. `Colors.grey` → `AppTheme.textSecondary` or `AppTheme.textDisabled`
8. `Colors.transparent` → `Colors.transparent` is OK for InkWell (keep)
9. Remove mock FAB in `ingredient_search_screen.dart` — replace with a proper custom ingredient dialog

- [ ] **Step 1:** Read all 6 files
- [ ] **Step 2-7:** Fix each file systematically
- [ ] **Step 8:** Run `flutter analyze`
- [ ] **Step 9:** Commit

### Task 20: Fix Hardcoded Colors — Voice + Onboarding + Telemetry + Shared Widgets

**Files:**
- Modify: `lib/features/voice/presentation/widgets/voice_bottom_sheet.dart`
- Modify: `lib/features/voice/presentation/widgets/voice_waveform.dart`
- Modify: `lib/features/voice/presentation/widgets/command_hint_ticker.dart`
- Modify: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- Modify: `lib/features/telemetry/presentation/pages/telemetry_screen.dart`
- Modify: `lib/core/error/error_snackbar_listener.dart`
- Modify: `lib/core/permissions/permission_banner.dart`

**Requirements:**
1. Replace ALL `Colors.*` with AppTheme tokens per the mapping in Task 18-19
2. Fix `permission_banner.dart` touch target: remove `constraints: BoxConstraints()` or set minimum 48x48
3. `Colors.green` → `AppTheme.accentMint`, `Colors.black` → `AppTheme.bgPrimary`
4. `Colors.amber.shade900` → appropriate dark theme snackbar color
5. `Colors.transparent` in telemetry_screen → keep (valid for InkWell)

- [ ] **Step 1:** Read all 7 files
- [ ] **Step 2-7:** Fix each file
- [ ] **Step 8:** Fix permission_banner touch target
- [ ] **Step 9:** Run `flutter analyze`
- [ ] **Step 10:** Commit

### Task 21: Add Form Validators to CalorieConfigScreen

**Files:**
- Modify: `lib/features/health/presentation/screens/calorie_config_screen.dart`

**Requirements:**
1. Add `validator` to all 3 TextFormField widgets (calories, weight, age)
2. Validate numeric input, reject empty/invalid values
3. Show user-friendly error messages

- [ ] **Step 1:** Read current file
- [ ] **Step 2:** Add `validator: (val) { if (val == null || val.isEmpty) return 'Required'; if (double.tryParse(val) == null) return 'Enter a valid number'; return null; }` pattern to each field
- [ ] **Step 3:** Replace `double.parse(val ?? '0')` with `double.tryParse(val!) ?? 0.0`
- [ ] **Step 4:** Run `flutter analyze`
- [ ] **Step 5:** Commit

### Task 22: Wire Up InlineErrorWidget and Shimmer Skeletons

**Files:**
- Modify: `lib/features/productivity/presentation/screens/productivity_screen.dart`
- Modify: `lib/features/health/presentation/screens/health_dashboard_screen.dart`
- Modify: `lib/features/finance/presentation/screens/finance_home_screen.dart`
- Modify: `lib/features/telemetry/presentation/screens/telemetry_home_screen.dart` (if skeleton exists)

**Requirements:**
1. Replace `CircularProgressIndicator()` with existing shimmer skeleton widgets where they exist
2. Replace `Text("Error: $msg")` with `InlineErrorWidget(message: msg, onRetry: () => bloc.add(LoadData()))`
3. Add proper empty state widgets for lists with no data

- [ ] **Step 1:** Verify existing shimmer skeleton and InlineErrorWidget files
- [ ] **Step 2:** Replace CircularProgressIndicator with shimmer in productivity, health, finance
- [ ] **Step 3:** Replace raw error Text with InlineErrorWidget in productivity, health, finance
- [ ] **Step 4:** Add empty states: ListEmptyState widget or simple "No data yet" message
- [ ] **Step 5:** Run `flutter analyze`
- [ ] **Step 6:** Commit

### Task 23: Fix BlacklistPreferencesStore Race Condition + KeroSpaceScreenReceiver Session Duration

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/telemetry/BlacklistPreferencesStore.kt`
- Modify: `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceScreenReceiver.kt`

**Requirements:**
1. In BlacklistPreferencesStore: use `commit()` instead of `apply()` or reorder cache invalidation to after write
2. In KeroSpaceScreenReceiver: add `lastWakeTimestamp` tracking and compute `sessionDurationMs` on SLEEP events

- [ ] **Step 1:** Read both files
- [ ] **Step 2:** Fix BlacklistPreferencesStore: move `_cachedPackages = null` after `apply()` or use `commit()`
- [ ] **Step 3:** In ScreenReceiver, add companion `var lastWakeTimestamp: Long = 0L`, update on WAKE, compute duration on SLEEP
- [ ] **Step 4:** Include `sessionDurationMs` in SLEEP event JSON
- [ ] **Step 5:** Verify no compilation errors
- [ ] **Step 6:** Commit

---

## P3: SPEC COMPLETENESS (4 tasks — larger scope)

### Task 24: Implement VoiceBloc Handling — NavigateIntent + BlockAppIntent + CommandParser Fixes

**Files:**
- Modify: `lib/features/voice/presentation/bloc/voice_bloc.dart`
- Modify: `lib/features/voice/domain/command_parser.dart`

**Requirements:**
1. Add `_onNavigateIntent` handler that calls `router.go(route)`
2. Add `_onBlockAppIntent` handler that calls `KeroSpacePlatformService.setBlacklistRules()`
3. Cache regexes in CommandParser as static final fields
4. Fix invalid decimal validation in `_parseExpense`

- [ ] **Step 1:** Read both files
- [ ] **Step 2:** Implement NavigateIntent handler using `GetIt` to get router or pass via event
- [ ] **Step 3:** Implement BlockAppIntent handler
- [ ] **Step 4:** Move regexes to static final in CommandParser
- [ ] **Step 5:** Add `double.tryParse` validation guard in `_parseExpense`
- [ ] **Step 6:** Run `flutter analyze`
- [ ] **Step 7:** Commit

### Task 25: Implement DecisionBreak Session Tracking in AccessibilityService

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceAccessibilityService.kt`
- Modify: `android/app/src/main/kotlin/com/example/kero_space/OverlayManager.kt`

**Requirements:**
1. Add `DecisionBreakTracker` — tracks whether a break was already served per packageName per session window
2. Before showing overlay, check if break already served → if yes, allow app
3. After overlay dismiss, mark break as served for that package
4. Log decision break outcome via event channel

- [ ] **Step 1:** Read both files
- [ ] **Step 2:** Add `DecisionBreakTracker` object with a `mutableMapOf<String, Long>()` to track last break time per package
- [ ] **Step 3:** Add check before `OverlayManager.show()` — if break served in last 30 min, skip overlay
- [ ] **Step 4:** After `OverlayManager.dismiss()`, record the break in tracker, emit event to Dart
- [ ] **Step 5:** Verify no compilation errors
- [ ] **Step 6:** Commit

### Task 26: Fix IsarService Race Condition + MainActivity Input Validation

**Files:**
- Modify: `lib/core/data/isar_service.dart`
- Modify: `android/app/src/main/kotlin/com/example/kero_space/MainActivity.kt`

**Requirements:**
1. Add synchronization guard in `IsarService.init()` — use `Completer` to prevent double-open
2. In MainActivity: clamp `durationSeconds` to max 300
3. In MainActivity: validate JSON schema before writing blacklist rules

- [ ] **Step 1:** Read both files
- [ ] **Step 2:** Add `static Completer<void>? _initCompleter` in IsarService, gate init with `if (_initCompleter != null) { await _initCompleter!.future; return; }`
- [ ] **Step 3:** In MainActivity, add `val clampedDuration = minOf(durationSeconds, 300)` before passing to OverlayManager
- [ ] **Step 4:** In MainActivity, add JSON validation: try-catch `JSONObject(rulesJson)` before persisting
- [ ] **Step 5:** Run `flutter analyze` for Dart changes
- [ ] **Step 6:** Commit

### Task 27: Populate Blocker Stats + Fix Finance Career Tab TODOs + Clean Up

**Files:**
- Modify: `lib/features/telemetry/presentation/bloc/telemetry_bloc.dart`
- Modify: `lib/features/finance/presentation/widgets/career_tab.dart`

**Requirements:**
1. Implement proper blocker stats query in TelemetryBloc (screen event + overlay data from Isar)
2. Replace string TODOs in career_tab.dart with proper string constants or enum values
3. Any remaining minor lint cleanup

- [ ] **Step 1:** Read both files
- [ ] **Step 2:** Implement `_onLoadBlockerStats` with actual Isar queries
- [ ] **Step 3:** Replace 'TODO', 'IN_PROGRESS', 'DONE' strings with enum or constants
- [ ] **Step 4:** Run `flutter analyze`
- [ ] **Step 5:** Commit
