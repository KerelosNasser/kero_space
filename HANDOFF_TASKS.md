# Kero Space Audit Remediation — Handoff Document

## Summary
**17 of 27 tasks complete** (all P0 ship-blockers + all P1 critical quality). Remaining: **10 tasks** (6 P2 design system + 1 P2 form validation + 1 P2 skeleton wiring + 1 P2 native race + 4 P3 spec completeness).

## Current State
- `flutter analyze`: **No issues** (as of last run)
- All 8 P0 tasks done: WakeWordService, KeroSpaceForegroundService, AccessibilityService, UsageStatsWorker, OverlayManager, AgentManager, Platform PII sanitization, CalendarChannelHandler
- All 9 P1 tasks done: VoiceBloc, ConfessionBloc, HealthBloc, FinanceBloc, ProductivityBloc, CalendarBloc, TelemetryBloc, ChurchBloc, Widget memory leaks

---

## Remaining Tasks

### P2: Design System Compliance (Tasks 18-20)
**Goal**: Replace ALL hardcoded `Colors.*` and raw `Color(0xFF...)` with `AppTheme` tokens across 17+ files.

**Token Map** (from `lib/core/app_theme.dart`):
| Hardcoded | Token |
|-----------|-------|
| `Colors.black` | `AppTheme.bgPrimary` |
| `Colors.white` (text) | `AppTheme.textPrimary` |
| `Colors.white` (icons) | `AppTheme.accentPrimary` |
| `Colors.grey` / `.shadeXXX` | `AppTheme.textSecondary` or `AppTheme.textDisabled` |
| `Colors.red` | `AppTheme.accentRose` |
| `Colors.green` | `AppTheme.accentMint` |
| `Colors.blue` | `AppTheme.accentCyan` |
| `Colors.orange` | `AppTheme.accentGold` |
| `Colors.purple` | `AppTheme.accentViolet` |
| `Color(0xFFBF5AF2)` | `AppTheme.accentViolet` |
| `Color(0xFF1C1C1E)` | `AppTheme.bgSurface` |
| `Color(0xFF2C2C2E)` | `AppTheme.bgElevated` |
| `Colors.transparent` | **KEEP** (valid for InkWell) |

**Files to Fix**:

**Task 18 - Church Screens** (4 files):
1. `lib/features/church/presentation/screens/ministry_kanban_screen.dart`
2. `lib/features/church/presentation/screens/attendance_screen.dart`
3. `lib/features/church/presentation/screens/confession_log_screen.dart`
4. `lib/features/church/presentation/screens/confession_auth_screen.dart`

**Task 19 - Productivity + Health + Home** (6 files):
1. `lib/features/productivity/presentation/screens/productivity_screen.dart`
2. `lib/features/productivity/presentation/widgets/daily_checklist.dart`
3. `lib/features/productivity/presentation/widgets/task_tree_view.dart`
4. `lib/features/health/presentation/screens/meal_log_screen.dart`
5. `lib/features/health/presentation/screens/ingredient_search_screen.dart` — **also remove mock FAB**
6. `lib/features/home/presentation/screens/home_screen.dart`

**Task 20 - Voice + Onboarding + Telemetry + Shared** (7 files):
1. `lib/features/voice/presentation/widgets/voice_bottom_sheet.dart`
2. `lib/features/voice/presentation/widgets/voice_waveform.dart`
3. `lib/features/voice/presentation/widgets/command_hint_ticker.dart`
4. `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
5. `lib/features/telemetry/presentation/pages/telemetry_screen.dart`
6. `lib/core/error/error_snackbar_listener.dart`
2. `lib/core/permissions/permission_banner.dart` — **also fix touch target** (remove `constraints: BoxConstraints()` or set min 48x48)

**Each file**: Add `import 'package:kero_space/core/app_theme.dart';` if missing, then systematically replace all color literals.

---

### P2: Task 21 - CalorieConfigScreen Form Validators
**File**: `lib/features/health/presentation/screens/calorie_config_screen.dart`
- Add `validator` to all 3 `TextFormField` (calories, weight, age)
- Validate numeric, reject empty/invalid
- Replace `double.parse()` with `double.tryParse() ?? 0.0`

---

### P2: Task 22 - Wire Up InlineErrorWidget & Shimmer Skeletons
**Files** (4 screens):
1. `lib/features/productivity/presentation/screens/productivity_screen.dart`
2. `lib/features/health/presentation/screens/health_dashboard_screen.dart`
3. `lib/features/finance/presentation/screens/finance_home_screen.dart`
4. `lib/features/telemetry/presentation/screens/telemetry_home_screen.dart` (if skeleton exists)

**Requirements**:
- Replace `CircularProgressIndicator()` with existing shimmer skeleton widgets
- Replace `Text("Error: $msg")` with `InlineErrorWidget(message: msg, onRetry: () => bloc.add(LoadData()))`
- Add empty state widgets for lists with no data

---

### P2: Task 23 - Native Race Conditions (2 Kotlin files)
**File 1**: `android/app/src/main/kotlin/com/example/kero_space/telemetry/BlacklistPreferencesStore.kt`
- Use `commit()` instead of `apply()` OR move cache invalidation (`_cachedPackages = null`) to AFTER write

**File 2**: `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceScreenReceiver.kt`
- Add companion `var lastWakeTimestamp: Long = 0L`
- Update on `ACTION_SCREEN_ON` (WAKE)
- Compute `sessionDurationMs = event.timestamp - lastWakeTimestamp` on `ACTION_SCREEN_OFF` (SLEEP)
- Include `sessionDurationMs` in SLEEP event JSON

---

### P3: Spec Completeness (Tasks 24-27)

**Task 24 - VoiceBloc Full Handler Coverage**
**Files**: `lib/features/voice/presentation/bloc/voice_bloc.dart`, `lib/features/voice/domain/command_parser.dart`
- Add `NavigateIntent` handler → `router.go(route)` via navigation service
- Add `BlockAppIntent` handler → `KeroSpacePlatformService.setBlacklistRules()`
- Cache regexes in `CommandParser` as `static final` fields
- Fix decimal validation in `_parseExpense` (use `double.tryParse`)

**Task 25 - DecisionBreak Session Tracking**
**Files**: `android/app/src/main/kotlin/com/example/kero_space/KeroSpaceAccessibilityService.kt`, `android/app/src/main/kotlin/com/example/kero_space/OverlayManager.kt`
- Add `DecisionBreakTracker` object with `mutableMapOf<String, Long>()` tracking last break per package
- Before `OverlayManager.show()`: check if break served in last 30 min → if yes, allow app
- After `OverlayManager.dismiss()`: record break in tracker, emit event to Dart
- Log decision break outcome via event channel

**Task 26 - IsarService Race + MainActivity Validation**
**Files**: `lib/core/data/isar_service.dart`, `android/app/src/main/kotlin/com/example/kero_space/MainActivity.kt`
- `IsarService.init()`: add synchronization guard with `Completer` to prevent double-open
- `MainActivity`: clamp `durationSeconds` to max 300 before passing to OverlayManager
- `MainActivity`: validate JSON schema before writing blacklist rules (try-catch `JSONObject(rulesJson)`)

**Task 27 - Final Cleanup**
**Files**: `lib/features/telemetry/presentation/bloc/telemetry_bloc.dart`, `lib/features/finance/presentation/widgets/career_tab.dart`
- Implement proper blocker stats query in TelemetryBloc (screen event + overlay data from Isar)
- Replace string TODOs in career_tab.dart ('TODO', 'IN_PROGRESS', 'DONE') with enum or constants
- Any remaining minor lint cleanup

---

## How to Continue

1. **Start with P2 Tasks 18-20** (color fixes) — these are mechanical but numerous. Do them file-by-file, run `flutter analyze` after each batch.
2. **Then Task 21** (CalorieConfigScreen validators) — straightforward.
3. **Then Task 22** (InlineErrorWidget + shimmer) — need to locate existing skeleton widgets first.
4. **Then Task 23** (Kotlin race fixes) — requires Android Studio / Kotlin knowledge.
5. **Then P3 Tasks 24-27** — larger scope, each ~2 hours.

**Key Commands**:
```bash
# Verify after each change
flutter analyze

# Check for remaining hardcoded colors
rg "Colors\." lib/ --type dart -c
```

**Architecture Notes**:
- All BLoCs registered as singletons in `injection.dart` — no changes needed there
- GetIt used for cross-BLoC dispatch (VoiceBloc pattern)
- `compute()` isolate used for CalendarBloc Coptic computation — follow same pattern for any CPU-bound work
- `AppTheme` tokens are the single source of truth for colors

**Pre-existing Warnings** (ignore, not blocking):
- 2 `prefer_initializing_formals` info hints in `finance_bloc.dart` (constructor pattern)

---

## Verification Checklist Before Handoff Complete
- [ ] `flutter analyze` → No issues
- [ ] `rg "Colors\." lib/ --type dart -c` → 0 matches (except `Colors.transparent`)
- [ ] All 3 widget controllers properly disposed
- [ ] All BLoC `copyWith` null bugs fixed (Health, Church, Telemetry)
- [ ] No stack trace leakage in catch blocks
- [ ] IsarService init race guarded