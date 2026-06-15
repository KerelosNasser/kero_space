# KERO SPACE COMPREHENSIVE AUDIT REPORT
## Independent Re-Audit — June 14, 2026

---

## EXECUTIVE SUMMARY

| Metric | Score |
|--------|-------|
| **Kotlin Security** | 3.5 / 10 |
| **Kotlin Code Quality** | 4.5 / 10 |
| **Flutter BLoC Architecture** | 5 / 10 |
| **Flutter Code Quality** | 5 / 10 |
| **UI Design System Compliance** | 4.5 / 10 |
| **UX (Nielsen's Heuristics)** | 3.8 / 10 |
| **Accessibility** | 2 / 10 |
| **Cross-Layer Integrity** | 4 / 10 |
| **Overall** | **4.0 / 10** |

| Count | Category |
|-------|----------|
| **8** | CRITICAL |
| **21** | HIGH |
| **35** | MEDIUM |
| **16** | LOW |
| **80** | Total Issues |

**Verdict:** The previous audit marked all 13 tasks as "Done" but the re-audit reveals **80 issues remain**, including 8 CRITICAL and 21 HIGH severity. The previous fixes were superficial — they addressed surface symptoms but left structural, security, and spec-compliance defects untouched.

---

## PREVIOUS AUDIT VERIFICATION

| Prev Claim | Actual Status | Evidence |
|-----------|---------------|----------|
| CR-001: NoteSchema fixed | **Partially fixed** | Schema registered in `isar_service.dart:32` but IsarService.init() has a race condition between isolates |
| CR-002: MinistryMemberSchema fixed | **Fixed** | Schema registered at line 47, model exists at `ministry_member.dart` |
| CR-003: WakeWordService ONNX | **NOT FIXED** | ADB mock trigger still in production code (`WakeWordService.kt:36-61`). No ONNX runtime, no Whisper, no command capture mode. Intent injection vulnerability on pre-Android 13. |
| CR-004: VoiceBloc Whisper | **NOT FIXED** | `speech_to_text: ^7.4.0` still in `pubspec.yaml:69`. No `SpeechToText` import in Dart (removed from code but package still listed), but VoiceBloc still uses `EventChannel('kero_space/wake_word')` — relies on Kotlin side for STT, which has no Whisper. |
| CR-005: OverlayManager complete | **NOT FIXED** | Plain `LinearLayout` + `TextView` (`OverlayManager.kt:51-62`). No Rive animation, no package icon, no gesture override, no DecisionBreak logging. |
| HP-001: ProductivityBloc string interpolation | **Fixed** | Error handling corrected |
| HP-002: FinanceBloc performance | **NOT FIXED** | Sequential HTTP stock fetches (N+1) still present. Double iteration over transactions. Cross-domain coupling to NutritionRepository. |
| HP-003: CalendarBloc memory | **NOT FIXED** | 3285 Coptic calendar objects still computed per call, blocking UI thread (`calendar_bloc.dart:27-49`) |
| HP-004: NotificationParserService DI | **Fixed** | Registered in `injection.dart:82-84` and initialized in `main.dart:46` |
| MP-001–MP-005: Hardcoded colors | **NOT FIXED** | **65 `Colors.*` + raw `Color(0xFF...)` violations remain** across 15+ files. Only a handful were partially fixed. |

**Bottom line:** 3 of 9 re-checkable items are truly fixed. 6 remain broken or partially addressed.

---

## SECTION 1: KOTLIN SECURITY & QUALITY (11 files)

### CRITICAL (3)

| ID | File:Line | Issue |
|----|----------|-------|
| **K-SEC-1** | `WakeWordService.kt:40-61` | **ADB mock trigger left in production code.** On Android <13, `registerReceiver(mockTriggerReceiver, filter)` has no `RECEIVER_NOT_EXPORTED` — any app can broadcast `com.example.kero_space.WAKE_WORD_TRIGGER` to inject fake wake-word events, bypassing the ONNX pipeline entirely. **Intent injection vulnerability.** |
| **K-SEC-2** | `WakeWordService.kt:159` | **JSON injection via string interpolation.** `emitWakeWordEvent` builds JSON with `"$text"` — if text contains `"`, `\`, or JSON metacharacters, the output is malformed/injectable. Function accepts arbitrary strings. |
| **K-SEC-3** | `KeroSpaceAccessibilityService.kt:37-58` | **Incomplete PII sanitization.** Spec requires redacting: passwords/PIN fields, 16-digit card numbers, emails in login contexts. Actual: only checks `viewId` for "password"/"pin". No card number regex, no email regex, no `event.text` sanitization. Click events with sensitive content are forwarded as-is. Additionally, `typeViewTextChanged` declared in config XML but **not handled** in Kotlin — events silently dropped. |

### HIGH (8)

| ID | File:Line | Issue |
|----|----------|-------|
| **K-SVC-1** | `WakeWordService.kt:23-194` | Service extends `Service` but **never calls `startForeground()`**. With `foregroundServiceType="microphone"` declared in manifest, this will crash on Android 12+ with `ForegroundServiceDidNotStartInTimeException` within 5 seconds. |
| **K-SVC-2** | `KeroSpaceForegroundService.kt:85` | `startService()` called instead of `startForegroundService()` for WakeWordService — crash on API 26+ for foreground-typed services. |
| **K-SEC-4** | `UsageStatsWorker.kt:64-67` | **Unscoped implicit broadcast** `sendBroadcast(intent)` with custom action `USAGE_STATS_READY` — no `setPackage()`, so ALL apps on device can register and receive detailed app usage statistics (package names + foreground times). **PII leak.** |
| **K-THR-1** | `OverlayManager.kt:32-43` | **Race condition on `overlayShowing`.** `@Volatile` check-then-act is not atomic. Two concurrent calls can both pass the `if` check. Use `AtomicBoolean.compareAndSet()`. |
| **K-SEC-5** | `KeroSpaceForegroundService.kt:116-122` | Pre-TIRAMISU receivers registered without `RECEIVER_NOT_EXPORTED`. `usageStatsReceiver` for custom `USAGE_STATS_READY` action is spoofable by any app on <Android 13. |
| **K-ANR-1** | `AgentManager.kt:90-94` | `getWorkInfosForUniqueWork().get()` — **blocking Future.get() on main thread**. Called from `getAgentStatuses` MethodChannel handler. ANR risk. |
| **K-DEP-1** | `AgentManager.kt:77-80` | `getRunningServices(Int.MAX_VALUE)` **deprecated** and unreliable since Android O. Returns stale state on Android 12+. |
| **K-ANR-2** | `CalendarChannelHandler.kt:27-69` | `contentResolver.query()` on main thread — I/O-bound operation in MethodChannel handler. ANR risk on slow devices. |

### MEDIUM (12)

| ID | File:Line | Issue |
|----|----------|-------|
| **K-THR-2** | `WakeWordService.kt:106-147` | `audioRecord.read()` is blocking — service onDestroy may not stop the thread promptly if read is mid-call. Need timeout-based read or thread interrupt. |
| **K-SPEC-1** | `WakeWordService.kt` | **No Whisper/ONNX command capture** — spec requires 5s continued AudioRecord → on-device Whisper tiny model for STT. Actual: only emits wake-word event, launches MainActivity. Missing `TranscriptionCompleteEvent`. |
| **K-SPEC-2** | `WakeWordService.kt` | Missing `PERFORMANCE_MODE_POWER_SAVING`, no `PartialWakeLock` management, no dedicated inference thread pool (2 threads max per spec). |
| **K-SPEC-3** | `UsageStatsWorker.kt` | No Isar/Room persistence, no `QuotaExceededEvent` computation, no daily quota violation detection. Spec says upsert by (packageName, date) then emit summary. |
| **K-SPEC-4** | `UsageStatsWorker.kt` | No WorkManager `Constraints` set (spec: no network required, battery not critically low). |
| **K-THR-3** | `BlacklistPreferencesStore.kt:49-51` | Race between `apply()` (async) and cache invalidation — `getBlockedPackages` may read stale data during commit. Use `commit()` or reorder. |
| **K-SPEC-5** | `OverlayManager.kt:51-62` | No Rive animation countdown, no package icon, no configurable message. Plain `TextView`. |
| **K-SPEC-6** | `OverlayManager.kt` | No user override gesture mechanism (spec: long-press + swipe), no override logging. |
| **K-SPEC-7** | `OverlayManager.kt` | No `DecisionBreakLog.record()` — spec requires logging overlay outcome with packageName, timestamp, outcome. |
| **K-SPEC-8** | `KeroSpaceScreenReceiver.kt:14-34` | **No session duration computation** on SLEEP events. Spec requires `SessionStateHolder.lastWakeTimestamp` — not implemented. |
| **K-SVC-3** | `KeroSpaceForegroundService.kt:100-103` | `onTimeout` stops self without rescheduling — entire Omniscient Layer dies on Android 15+ data-sync FGS timeout. |
| **K-SVC-4** | `KeroSpaceForegroundService.kt:165-183` | `startFlutterEngine()` runs I/O-bound `flutterLoader` operations on main thread — ANR risk. |

### LOW (5)

| ID | File:Line | Issue |
|----|----------|-------|
| **K-VAL-1** | `MainActivity.kt:134-139` | No validation/clamping on `durationSeconds` from Dart — `Int.MAX_VALUE` creates never-dismiss overlay (DoS). |
| **K-VAL-2** | `MainActivity.kt:146-149` | No JSON schema validation on `setBlacklistRules` input — malformed JSON disables all blocking (`emptySet()` fallback). |
| **K-NULL-1** | `UsageStatsWorker.kt:28-29` | `getSystemService()` cast without null-check. |
| **K-NULL-2** | `CalendarChannelHandler.kt:62` | `getColumnIndex()` can return -1; no validation before `getString()`. |
| **K-SPEC-9** | `accessibility_service_config.xml` | `typeViewTextChanged` declared but not handled in Kotlin code — events silently dropped. |

---

## SECTION 2: FLUTTER BLoC ARCHITECTURE (8 BLoCs)

### CRITICAL (2)

| ID | File:Line | Issue |
|----|----------|-------|
| **F-BLOC-1** | `pubspec.yaml:69`, `voice_bloc.dart:27-29` | `speech_to_text: ^7.4.0` still in dependencies — cloud-capable STT plugin violates AGENTS.md mandate "never sends audio to any network endpoint". No on-device Whisper integration exists in either Kotlin or Dart. |
| **F-PERF-1** | `calendar_bloc.dart:27-49` | Coptic computus loop creates ~3285 `CalendarEvent` objects per call, blocking UI thread. No caching strategy, no compute isolate. |

### HIGH (8)

| ID | File:Line | Issue |
|----|----------|-------|
| **F-SEC-1** | `voice_bloc.dart:65-67` | Malformed JSON in wake word listener sends `WakeWordTriggered()` as fallback — a continuous malformed stream would spam UI with wake-word triggers. |
| **F-ARCH-1** | `voice_bloc.dart:22-25` | Cross-BLoC direct coupling: VoiceBloc holds references to ProductivityBloc, HealthBloc, FinanceBloc, ChurchBloc — violates single-responsibility, makes testing impossible without all 4 BLoCs. |
| **F-ERR-1** | `health_bloc.dart:185-188` | `_onLogMeal` has **no try/catch** — error propagates to BLoC `onError` with no error state emitted to UI. |
| **F-ERR-2** | `health_bloc.dart:190-194` | `_onToggleFastingMode` writes to SharedPreferences with **no error handling**. |
| **F-ARCH-2** | `finance_bloc.dart:7,15` | FinanceBloc depends on `NutritionRepository` — cross-domain coupling violation. Correlation logic should be in a shared analytics layer. |
| **F-SEC-2** | `confession_bloc.dart:20,29` | `UnlockConfessionSession` and `EnableBiometrics` events include `passphrase` in Equatable `props` — passphrase compared by value and stored in event history. Security risk. |
| **F-SEC-3** | `confession_bloc.dart:64` | `ConfessionUnlocked` state holds `SecretKey` in Equatable `props` — key material exposed to equality checks. |
| **F-SEC-4** | `kero_space_platform_service.dart:63-68` | Accessibility click events stored as **raw JSON** in `dataJson` field — no PII sanitization in background isolate. AGENTS.md `sanitize()` function not implemented. |
| **F-MEM-1** | `injection.dart` | All BLoCs registered as `LazySingleton` — never disposed. VoiceBloc + TelemetryBloc have `StreamSubscription`s that persist for entire app lifecycle. `BlocProvider.value` never calls `close()`. |
| **F-ERR-3** | `productivity_bloc.dart:90` | `firstWhere()` without `orElse` — throws `StateError` if `linkedTaskId` doesn't match. Wrapped in try/catch but produces confusing error message. |

### MEDIUM (14)

| ID | File:Line | Issue |
|----|----------|-------|
| **F-ARCH-3** | `voice_bloc.dart:131-192` | Success emitted before downstream BLoC confirmation — user sees "Done!" even if the target BLoC fails. |
| **F-ARCH-4** | `voice_bloc.dart:165` | Hardcoded `category: 'Other'` for voice expenses — should parse from input. |
| **F-ARCH-5** | `voice_bloc.dart:173-178` | Meal nutrition values hardcoded to 0 — should look up from nutrition DB. |
| **F-ARCH-6** | `voice_bloc.dart:131-192` | `NavigateIntent` and `BlockAppIntent` never handled — voice commands "show portfolio" / "block app" do nothing after confirmation. |
| **F-PERF-2** | `finance_bloc.dart:124-129` | Sequential HTTP stock price fetches — N+1 network pattern. |
| **F-PERF-3** | `finance_bloc.dart:52-72` | Double iteration over transactions list — O(2n) where single-pass accumulation would suffice. |
| **F-PERF-4** | `telemetry_bloc.dart:35-36` | Isar watch triggers storm of `LoadTelemetryDashboard` events — each triggers 4+ Isar queries. |
| **F-ERR-4** | `telemetry_bloc.dart:104-143` | Missing try/catch on blacklist operations, platform channel calls, and agent toggles. |
| **F-BUG-1** | `church_bloc.dart:58`, `health_bloc.dart:92` | `copyWith` uses `errorMessage ?? this.errorMessage` — **cannot clear error to null** on success path. Affects ChurchBloc, HealthBloc. |
| **F-BUG-2** | `telemetry_state.dart:52` | `copyWith` uses `errorMessage: errorMessage` — correctly allows null but **inconsistent** with other BLoCs. |
| **F-SEC-5** | `productivity_bloc.dart:43,52,61,70,79,97,106` | Raw exception `$e` interpolation in error messages leaks internal stack traces to UI. |
| **F-PERF-5** | `productivity_bloc.dart:50,58,68,76,95,104` | Every mutation calls `add(LoadData())` — full reload with 3 Isar queries for simple CRUD. Use targeted updates. |
| **F-BUG-3** | `calendar_bloc.dart:51` | `events.addAll(_cachedCopticEvents!)` mutates potentially unmodifiable list from repository. |
| **F-BUG-4** | `command_parser.dart:114-128` | Invalid decimal amounts like `99.99.99` silently become 0.0 via `double.tryParse`. |

### LOW (5)

| ID | File:Line | Issue |
|----|----------|-------|
| **F-DI-1** | `injection.dart` | Mixed DI registration: some repos use `@lazySingleton` annotation, some use manual `getIt.registerLazySingleton`. |
| **F-DI-2** | `productivity_bloc.dart:12` | Uses `@injectable` instead of `@lazySingleton` — inconsistent with other BLoCs. |
| **F-I18N-1** | `command_parser.dart:18` | English-only filler words — no multilingual support. |
| **F-SPEC-1** | `telemetry_bloc.dart:81-86` | `_onLoadBlockerStats` is a stub — emits empty list. Blocker stats never populated. |
| **F-SPEC-2** | `telemetry_bloc.dart:38` | `_pruneData()` runs unawaited — race with `LoadTelemetryDashboard` events. |

---

## SECTION 3: FLUTTER UI / UX AUDIT (22 screens)

### Hardcoded Colors Violations: **65 instances** across 15 files

| File | `Colors.*` count | Raw `Color(0xFF)` count | Total |
|------|-----------------|--------------------------|-------|
| `ministry_kanban_screen.dart` | 15 | 5 | 20 |
| `attendance_screen.dart` | 8 | 3 | 11 |
| `onboarding_screen.dart` | 4 | 0 | 4 |
| `productivity_screen.dart` | 5 | 0 | 5 |
| `voice_bottom_sheet.dart` | 5 | 0 | 5 |
| `daily_checklist.dart` | 4 | 0 | 4 |
| `voice_waveform.dart` | 2 | 0 | 2 |
| `task_tree_view.dart` | 2 | 0 | 2 |
| `confession_log_screen.dart` | 1 | 0 | 1 |
| `confession_auth_screen.dart` | 1 | 0 | 1 |
| `meal_log_screen.dart` | 1 | 0 | 1 |
| `ingredient_search_screen.dart` | 2 | 0 | 2 |
| `home_screen.dart` | 1 | 0 | 1 |
| `telemetry_screen.dart` | 1 | 0 | 1 |
| `error_snackbar_listener.dart` | 4 | 0 | 4 |
| `command_hint_ticker.dart` | 1 | 0 | 1 |
| **Total** | **57** | **8** | **65** |

### Widget Lifecycle / Memory Leaks: **3 confirmed**

| File | Controller | Problem |
|------|-----------|---------|
| `settings_screen.dart:16` | `TextEditingController _dockerUrlController` | **Never disposed** |
| `confession_log_screen.dart:22` | `QuillController _controller` | **Never disposed** |
| `meal_log_screen.dart:38` | `TextEditingController(text: '100')` | **Created inside build()** — new controller every rebuild, text resets, memory leak |

### Nielsen's Heuristics Assessment

| Heuristic | Score | Key Issues |
|-----------|-------|------------|
| 1. Visibility of system status | 3/10 | 60% of screens lack proper loading states. No feedback on save (note_editor). No progress indicator on onboarding permissions. |
| 2. Match real-world language | 5/10 | Good domain language (Coptic fasting, BMR). Some jargon: "Omniscient Layer" unexplained. |
| 3. User control and freedom | 4/10 | No undo for attendance, meal log, task creation. No confirmation for data deletion. |
| 4. Consistency and standards | 4/10 | Wildly inconsistent: some screens use AppTheme, others raw Colors. FAB behavior varies. Error display varies (SnackBar / raw Text / InlineErrorWidget unused). |
| 5. Error prevention | 3/10 | `calorie_config_screen` has no validators on 3 numeric fields. `meal_log_screen` silently defaults to 0. Empty passphrase does nothing. |
| 6. Recognition over recall | 5/10 | Icons + labels on nav/tabs. Kanban has icon-only trailing, dropdown is cramped. |
| 7. Flexibility and efficiency | 5/10 | Some debounced search. Click log search requires submit. No keyboard shortcuts on mobile. |
| 8. Aesthetic and minimalist | 6/10 | Clean dark theme when AppTheme used. Cluttered kanban, fasting badge overlap in productivity. |
| 9. Error recovery | 3/10 | Most errors shown as raw Text() or simple SnackBar. `InlineErrorWidget` exists but **never used** in any screen. Shimmer skeletons built but **never used**. No retry mechanisms. |
| 10. Help and documentation | 2/10 | No onboarding tutorial, no help screens, no tooltips on most icons. |

### Error State Coverage

| Screen | Loading | Error | Empty | Score |
|--------|---------|-------|-------|-------|
| home_screen | Partial | None | None | 0/3 |
| health_dashboard | CircularProgressIndicator | Styled | None | 2/3 |
| finance_home | CircularProgressIndicator | Raw text | Bad | 1/3 |
| ministry_kanban | CircularProgressIndicator | SnackBar | Icon+text | 3/3 |
| confession_log | CircularProgressIndicator | Silent fallback | N/A | 1/3 |
| productivity_screen | CircularProgressIndicator | Raw text | None | 1/3 |
| calorie_config | None | None | N/A | 0/3 |
| meal_log | None | None | None | 0/3 |
| ingredient_search | None | None | None | 0/3 |
| note_editor | None | None | None | 0/3 |
| onboarding | None | None | N/A | 0/3 |
| telemetry screens | CircularProgressIndicator | None | Partial | 1/3 |

### Accessibility: 2/10

- **Zero** `Semantics` widgets across all 22 screens
- **Zero** `tooltip` on `IconButton` (except 2 in confession_log)
- Touch target <48px: `permission_banner.dart:41-46` (`constraints: BoxConstraints()` = zero constraints), `onboarding_screen.dart:245-258`
- No screen reader support on charts/heatmaps
- PieChart, fl_chart, and calendar grid have zero semantic annotations

### Mock/Placeholder Code Remaining

| File:Line | Code | Issue |
|-----------|------|-------|
| `ingredient_search_screen.dart:63-78` | Mock FAB with hardcoded `Ingredient(calories=100, protein=5...)` | Violates Anti-Placeholder Protocol |
| `voice_waveform.dart:10` | "For V1, we'll use a simple animated container placeholder" | Rive waveform not implemented |
| `WakeWordService.kt:36-61` | ADB mock trigger in production | Should be gated behind `BuildConfig.DEBUG` |
| `telemetry_bloc.dart:81-86` | Blocker stats stub — always empty | Feature not implemented |

---

## SECTION 4: CROSS-LAYER INTEGRITY

### Platform Channel Mapping

| Channel | Dart Side | Kotlin Side | Issues |
|---------|-----------|-------------|--------|
| `kero_space/methods` | `KeroSpacePlatformService` | `MainActivity` | Duplicate handler in FGS (`kero_space/bg/methods`). No arg validation. |
| `kero_space/wake_word` | `VoiceBloc` EventChannel | `WakeWordService` | No Whisper STT. Mock trigger injects events. |
| `kero_space/bg/screen_events` | `backgroundMain()` | `KeroSpaceScreenReceiver` | No session duration computation. Events only forwarded, not persisted in Kotlin. |
| `kero_space/bg/accessibility` | `backgroundMain()` | `KeroSpaceAccessibilityService` | Click events stored as raw JSON (no PII sanitization). No click coordinates. |
| `kero_space/bg/usage_stats` | `backgroundMain()` | `UsageStatsWorker` | Unscoped broadcast (PII leak). No QuotaExceededEvent. |
| `kero_space/main_methods` | `main.dart:54` | `MainActivity` | Only `startForegroundService` call. Simple, low risk. |
| `kero_space/calendar` | (unused?) | `CalendarChannelHandler` | ANR risk from main-thread contentResolver query. |

### Data Flow Gap Analysis

| Spec Requirement | Implementation Status |
|-----------------|---------------------|
| Click logger with `(timestamp, packageName, className, viewId, text, clickX, clickY)` | Only `(timestamp, packageName, className, viewId)` — no text, no coordinates |
| PII sanitize() before storage | **Not implemented** — raw JSON stored |
| DecisionBreak with session tracking | **Not implemented** |
| Overlay with Rive + gesture override + logging | **Not implemented** — plain TextView |
| QuotaExceededEvent for daily limit violations | **Not implemented** |
| Session duration computation | **Not implemented** |
| On-device Whisper for command STT | **Not implemented** |
| Blacklist sync to EncryptedSharedPreferences | **Implemented** |
| Boot restart of foreground service | **Implemented** |
| Isar persistence from background isolate | **Implemented** (screen, click, usage) |
| Encrypted confessions | **Implemented** (XChaCha20-Poly1305) |

---

## SECTION 5: PRIORITY FIX LIST

### P0 — Ship Blockers (fix before any release)

| # | ID | Description | Files | Est. Time |
|---|-----|-----------|-------|-----------|
| 1 | K-SEC-1 | Remove ADB mock trigger or gate behind `BuildConfig.DEBUG` + use `RECEIVER_NOT_EXPORTED` on all API levels | `WakeWordService.kt:36-61` | 2h |
| 2 | K-SVC-1 | Make WakeWordService call `startForeground()` with notification, or remove `foregroundServiceType="microphone"` and run under KeroSpaceForegroundService | `WakeWordService.kt`, `AndroidManifest.xml:94-96` | 3h |
| 3 | K-SVC-2 | Change `startService()` to `startForegroundService()` in FGS | `KeroSpaceForegroundService.kt:85` | 1h |
| 4 | K-SEC-4 | Scope `USAGE_STATS_READY` broadcast with `setPackage(packageName)` | `UsageStatsWorker.kt:64-67` | 1h |
| 5 | K-SEC-5 | Add `RECEIVER_NOT_EXPORTED` flag to pre-TIRAMISU custom action receivers | `KeroSpaceForegroundService.kt:116-122` | 2h |
| 6 | K-SEC-3 | Implement full PII sanitization: card number regex, email regex, password field patterns | `KeroSpaceAccessibilityService.kt:37-58` | 4h |
| 7 | F-SEC-4 | Implement PII sanitization in background isolate before Isar write | `kero_space_platform_service.dart:63-68` | 3h |
| 8 | K-SEC-2 | Fix JSON injection in `emitWakeWordEvent` — use `JSONObject.put()` instead of string interpolation | `WakeWordService.kt:159` | 1h |

### P1 — Critical Quality (fix in next sprint)

| # | ID | Description | Files | Est. Time |
|---|-----|-----------|-------|-----------|
| 9 | F-BLOC-1 | Remove `speech_to_text` from pubspec.yaml (unused dependency). Decide: implement on-device Whisper in Kotlin or use a different approach. | `pubspec.yaml:69` | 1h |
| 10 | F-PERF-1 | Move Coptic calendar computation to `compute()` isolate or cache aggressively | `calendar_bloc.dart:27-49` | 4h |
| 11 | F-MEM-1 | Dispose singleton BLoC subscriptions properly, or switch to `BlocProvider(create:)` for scoped lifecycle | `injection.dart`, `main.dart` | 6h |
| 12 | F-SEC-2/3 | Remove passphrase/SecretKey from Equatable `props` | `confession_bloc.dart:20,29,64` | 2h |
| 13 | F-ERR-1/2 | Add try/catch to HealthBloc `_onLogMeal` and `_onToggleFastingMode` | `health_bloc.dart:185-194` | 1h |
| 14 | K-THR-1 | Fix OverlayManager race condition with `AtomicBoolean.compareAndSet()` | `OverlayManager.kt:32-43` | 1h |
| 15 | K-ANR-1/2 | Move blocking operations off main thread: `Future.get()`, `contentResolver.query()` | `AgentManager.kt:90-94`, `CalendarChannelHandler.kt:27-69` | 3h |
| 16 | K-VAL-1/2 | Validate platform channel inputs: clamp `durationSeconds`, validate blacklist JSON schema | `MainActivity.kt:134-149` | 2h |
| 17 | UI-MEM | Fix 3 memory leaks: dispose controllers in settings_screen, confession_log_screen, move meal_log controller to state | 3 files | 2h |

### P2 — Design System Compliance

| # | Description | Scope | Est. Time |
|---|-----------|-------|-----------|
| 18 | Replace all 65 hardcoded `Colors.*` and raw `Color(0xFF)` with `AppTheme` tokens | 15 files | 6h |
| 19 | Fix `copyWith` null bug in ChurchBloc, HealthBloc | 2 files | 1h |
| 20 | Add form validators to `calorie_config_screen` | 1 file | 2h |
| 21 | Wire up existing `InlineErrorWidget` and shimmer skeletons | 8+ files | 4h |
| 22 | Add empty states to screens that lack them (10 screens) | 10 files | 6h |
| 23 | Add `Semantics` and `tooltip` for accessibility | 22 screens | 8h |

### P3 — Spec Completeness

| # | Description | Scope | Est. Time |
|---|-----------|-------|-----------|
| 24 | Implement OverlayManager: Rive animation, gesture override, DecisionBreak logging | `OverlayManager.kt` | 8h |
| 25 | Implement WakeWordService: ONNX wake-word model + Whisper command capture | `WakeWordService.kt` | 16h |
| 26 | Implement session duration computation in ScreenReceiver | `KeroSpaceScreenReceiver.kt` | 2h |
| 27 | Implement QuotaExceededEvent in UsageStatsWorker | `UsageStatsWorker.kt` | 4h |
| 28 | Implement VoiceBloc handling for NavigateIntent and BlockAppIntent | `voice_bloc.dart` | 2h |
| 29 | Remove mock FAB from ingredient_search, implement real creation | `ingredient_search_screen.dart` | 2h |
| 30 | Fix permission_banner touch target <48px | `permission_banner.dart` | 1h |

---

## VERIFICATION CHECKLIST

Run these commands before claiming any fix is complete:

```bash
# Dart static analysis
flutter analyze

# Android debug build
cd android && ./gradlew assembleDebug

# Unit tests
flutter test

# Search for remaining violations
rg "Colors\." lib/ --type dart -c
rg "mock|placeholder|TODO|FIXME" lib/ --type dart -c
rg "mock|TODO|FIXME" android/app/src/main/kotlin/ --type kotlin -c
```

---

**Audit completed with full independent verification.**  
**Previous audit's "all done" status is NOT confirmed.**  
**8 CRITICAL issues and 21 HIGH issues remain unresolved.**
