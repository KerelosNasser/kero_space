# Phase 7 — Telemetry Dashboard & Behavioral Analytics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface all agent-collected telemetry (screen events, app usage, click logs, blocker activity) into actionable, glanceable visualizations with a full blacklist management and agent control center.

**Architecture:** Clean Architecture — `TelemetryBloc` aggregates three Isar-backed repositories. Blacklist state lives in both Dart (UI) and Kotlin (`EncryptedSharedPreferences`) synchronized via `MethodChannel`. All screens under `/telemetry` route.

**Tech Stack:** Flutter BLoC, Isar (existing collections), `fl_chart`, `CustomPainter`, `device_apps`, `MethodChannel('kero_space/methods')`, `EncryptedSharedPreferences` (Kotlin)

---

## Multi-Agent Decision Log

| # | Decision | Rationale |
|---|---|---|
| D1 | Blacklist synced to Kotlin via `setBlacklistRules(json)` MethodChannel call | `flutter_secure_storage` inaccessible from Kotlin background thread; `EncryptedSharedPreferences` is thread-safe |
| D2 | Click log browser uses 50-per-page offset pagination | High click volume (1000s/day) → OOM risk with unbounded load |
| D3 | `toggleAgent(agentId, bool)` MethodChannel call controls Android services | Foreground service start/stop must happen natively |
| D4 | Isar date grouping done in Dart after bounded 7-day query | Isar has no native date GROUP BY |
| D5 | `device_apps` package + `QUERY_ALL_PACKAGES` permission | Required for installed apps list in blacklist manager |
| D6 | Isar `watchLazy()` stream triggers dashboard refresh | Battery-safe reactive pattern — no polling timer |
| D7 | Agent toggle cards show one-line status summary | ADHD UX: mystery panel without context is unusable |
| D8 | Resistance rate shows plain-English subtitle | "87% resistance" → "You resisted the urge 87% of the time" |
| D9 | App list in blacklist manager sorted by foreground time DESC | Filtered to apps already in `AppUsageRecord` for usability |
| D10 | Emergency bypass puzzle = 3-digit arithmetic shown for 3s | Bounded, specified, enough friction without rage-quit |

---

## File Map

### New Files (Dart)
```
lib/features/telemetry/
  data/
    repositories/
      screen_event_repository.dart
      app_usage_repository.dart
      click_log_repository.dart
      blacklist_repository.dart
    models/
      blacklist_rule.dart            (pure Dart model, no Isar)
      blocker_stat.dart              (pure Dart aggregate model)
  presentation/
    bloc/
      telemetry_bloc.dart
      telemetry_event.dart
      telemetry_state.dart
    screens/
      telemetry_home_screen.dart     (tab host)
      screen_time_overview_screen.dart
      unlock_heatmap_screen.dart
      blocker_effectiveness_screen.dart
      blacklist_management_screen.dart
      click_log_browser_screen.dart
      omniscient_control_center_screen.dart
    widgets/
      heatmap_painter.dart
      agent_toggle_card.dart
      bypass_puzzle_dialog.dart
      app_usage_tile.dart
      click_log_entry_tile.dart
      resistance_rate_card.dart
```

### Modified Files
```
lib/core/di/injection.dart
lib/core/router.dart
lib/core/data/kero_space_platform_service.dart
pubspec.yaml                           (add device_apps)
android/app/src/main/AndroidManifest.xml  (add QUERY_ALL_PACKAGES)
android/app/src/main/kotlin/.../MainActivity.kt
```

### New Files (Kotlin)
```
android/app/src/main/kotlin/.../telemetry/BlacklistPreferencesStore.kt
```

### Test Files
```
test/features/telemetry/
  repositories/screen_event_repository_test.dart
  bloc/telemetry_bloc_test.dart
  widgets/heatmap_painter_test.dart
```

---

## Task 1: Data Models & Repositories (pure Dart)

**Files:**
- Create: `lib/features/telemetry/data/models/blacklist_rule.dart`
- Create: `lib/features/telemetry/data/models/blocker_stat.dart`
- Create: `lib/features/telemetry/data/repositories/screen_event_repository.dart`
- Create: `lib/features/telemetry/data/repositories/app_usage_repository.dart`
- Create: `lib/features/telemetry/data/repositories/click_log_repository.dart`
- Create: `lib/features/telemetry/data/repositories/blacklist_repository.dart`
- Test: `test/features/telemetry/repositories/screen_event_repository_test.dart`

- [ ] **Step 1.1: Create BlacklistRule model**

```dart
// lib/features/telemetry/data/models/blacklist_rule.dart
import 'dart:convert';

class BlacklistRule {
  final String packageName;
  final List<TimeWindow> allowedWindows;
  final int dailyQuotaMinutes;
  final int decisionBreakSeconds;

  const BlacklistRule({
    required this.packageName,
    this.allowedWindows = const [],
    this.dailyQuotaMinutes = 0,
    this.decisionBreakSeconds = 30,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'allowedWindows': allowedWindows.map((w) => w.toJson()).toList(),
    'dailyQuotaMinutes': dailyQuotaMinutes,
    'decisionBreakSeconds': decisionBreakSeconds,
  };

  factory BlacklistRule.fromJson(Map<String, dynamic> json) => BlacklistRule(
    packageName: json['packageName'] as String,
    allowedWindows: (json['allowedWindows'] as List<dynamic>)
        .map((e) => TimeWindow.fromJson(e as Map<String, dynamic>))
        .toList(),
    dailyQuotaMinutes: json['dailyQuotaMinutes'] as int,
    decisionBreakSeconds: json['decisionBreakSeconds'] as int,
  );

  static List<BlacklistRule> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => BlacklistRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<BlacklistRule> rules) =>
      jsonEncode(rules.map((r) => r.toJson()).toList());
}

class TimeWindow {
  final int startHour;
  final int endHour;

  const TimeWindow({required this.startHour, required this.endHour});

  Map<String, dynamic> toJson() => {'startHour': startHour, 'endHour': endHour};
  factory TimeWindow.fromJson(Map<String, dynamic> json) =>
      TimeWindow(startHour: json['startHour'] as int, endHour: json['endHour'] as int);
}
```

- [ ] **Step 1.2: Create BlockerStat aggregate model**

```dart
// lib/features/telemetry/data/models/blocker_stat.dart
class BlockerStat {
  final String packageName;
  final int blockedAttempts;
  final int grantedOverrides;
  final DateTime date;

  const BlockerStat({
    required this.packageName,
    required this.blockedAttempts,
    required this.grantedOverrides,
    required this.date,
  });

  double get resistanceRate =>
      blockedAttempts + grantedOverrides == 0
          ? 0
          : blockedAttempts / (blockedAttempts + grantedOverrides);

  String get resistanceLabel =>
      '${(resistanceRate * 100).toStringAsFixed(0)}% — '
      'You resisted the urge ${(resistanceRate * 100).toStringAsFixed(0)}% of the time';
}
```

- [ ] **Step 1.3: Write failing test for ScreenEventRepository**

```dart
// test/features/telemetry/repositories/screen_event_repository_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kero_space/features/telemetry/data/models/telemetry_collections.dart';
import 'package:kero_space/features/telemetry/data/repositories/screen_event_repository.dart';

void main() {
  late Isar isar;
  late ScreenEventRepository repo;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open([ScreenEventSchema], directory: Directory.systemTemp.path);
    repo = ScreenEventRepository(isar);
  });

  tearDown(() async => isar.close(deleteFromDisk: true));

  test('getUnlockEvents returns only UNLOCK events in date range', () async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.screenEvents.putAll([
        ScreenEvent()
          ..deviceId = 'd1'
          ..platform = 'android'
          ..eventType = 'UNLOCK'
          ..timestamp = now.subtract(const Duration(hours: 1)),
        ScreenEvent()
          ..deviceId = 'd1'
          ..platform = 'android'
          ..eventType = 'SLEEP'
          ..timestamp = now.subtract(const Duration(hours: 2)),
      ]);
    });

    final results = await repo.getUnlockEvents(
      from: now.subtract(const Duration(days: 1)),
      to: now,
    );

    expect(results.length, 1);
    expect(results.first.eventType, 'UNLOCK');
  });

  test('getTotalScreenTimeMs sums WAKE-to-SLEEP durations', () async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.screenEvents.putAll([
        ScreenEvent()..deviceId='d1'..platform='android'..eventType='WAKE'
          ..timestamp = now.subtract(const Duration(hours: 2)),
        ScreenEvent()..deviceId='d1'..platform='android'..eventType='SLEEP'
          ..timestamp = now.subtract(const Duration(hours: 1)),
      ]);
    });

    final ms = await repo.getTotalScreenTimeMs(
      from: now.subtract(const Duration(days: 1)),
      to: now,
    );

    expect(ms, closeTo(3600000, 5000));
  });
}
```

- [ ] **Step 1.4: Run test — verify FAIL**
```powershell
rtk flutter test test/features/telemetry/repositories/screen_event_repository_test.dart -v
```
Expected: FAIL — `ScreenEventRepository` not found.

- [ ] **Step 1.5: Implement ScreenEventRepository**

```dart
// lib/features/telemetry/data/repositories/screen_event_repository.dart
import 'package:isar/isar.dart';
import '../models/telemetry_collections.dart';

class ScreenEventRepository {
  final Isar _isar;
  ScreenEventRepository(this._isar);

  Future<List<ScreenEvent>> getUnlockEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    return _isar.screenEvents
        .filter()
        .eventTypeEqualTo('UNLOCK')
        .timestampBetween(from, to)
        .sortByTimestamp()
        .findAll();
  }

  Future<List<ScreenEvent>> getAllEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    return _isar.screenEvents
        .filter()
        .timestampBetween(from, to)
        .sortByTimestamp()
        .findAll();
  }

  Future<int> getTotalScreenTimeMs({
    required DateTime from,
    required DateTime to,
  }) async {
    final events = await getAllEvents(from: from, to: to);
    int totalMs = 0;
    DateTime? lastWake;
    for (final e in events) {
      if (e.eventType == 'WAKE') {
        lastWake = e.timestamp;
      } else if (e.eventType == 'SLEEP' && lastWake != null) {
        totalMs += e.timestamp.difference(lastWake).inMilliseconds;
        lastWake = null;
      }
    }
    return totalMs;
  }

  /// Returns 7×24 matrix: matrix[dayIndex][hour] = unlock count.
  Future<List<List<int>>> getUnlockHeatmap({required DateTime weekStart}) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final unlocks = await getUnlockEvents(from: weekStart, to: weekEnd);
    final matrix = List.generate(7, (_) => List.filled(24, 0));
    for (final e in unlocks) {
      final dayIndex = e.timestamp.difference(weekStart).inDays.clamp(0, 6);
      final hour = e.timestamp.hour;
      matrix[dayIndex][hour]++;
    }
    return matrix;
  }

  Stream<void> watchChanges() => _isar.screenEvents.watchLazy();
}
```

- [ ] **Step 1.6: Run test — verify PASS**
```powershell
rtk flutter test test/features/telemetry/repositories/screen_event_repository_test.dart -v
```

- [ ] **Step 1.7: Implement AppUsageRepository**

```dart
// lib/features/telemetry/data/repositories/app_usage_repository.dart
import 'package:isar/isar.dart';
import '../models/telemetry_collections.dart';

class AppUsageRepository {
  final Isar _isar;
  AppUsageRepository(this._isar);

  Future<List<AppUsageRecord>> getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _isar.appUsageRecords
        .filter()
        .dateBetween(startOfDay, now)
        .sortByForegroundMsDesc()
        .findAll();
  }

  Future<List<(DateTime, int)>> getWeeklyScreenTimeTotals() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final records = await _isar.appUsageRecords
        .filter()
        .dateBetween(weekAgo, now)
        .findAll();

    final Map<String, int> byDate = {};
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month}-${r.date.day}';
      byDate[key] = (byDate[key] ?? 0) + r.foregroundMs;
    }

    return byDate.entries.map((e) {
      final parts = e.key.split('-');
      return (DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])), e.value);
    }).toList()..sort((a, b) => a.$1.compareTo(b.$1));
  }

  Stream<void> watchChanges() => _isar.appUsageRecords.watchLazy();
}
```

- [ ] **Step 1.8: Implement ClickLogRepository**

```dart
// lib/features/telemetry/data/repositories/click_log_repository.dart
import 'package:isar/isar.dart';
import '../models/telemetry_collections.dart';

class ClickLogRepository {
  final Isar _isar;
  static const int pageSize = 50;

  ClickLogRepository(this._isar);

  Future<List<TelemetryEvent>> getClickLogs({
    String? packageName,
    DateTime? from,
    DateTime? to,
    int page = 0,
  }) async {
    final rangeFrom = from ?? DateTime.now().subtract(const Duration(days: 7));
    final rangeTo = to ?? DateTime.now();

    var query = _isar.telemetryEvents
        .filter()
        .nameEqualTo('click')
        .timestampBetween(rangeFrom, rangeTo);

    return query
        .sortByTimestampDesc()
        .offset(page * pageSize)
        .limit(pageSize)
        .findAll();
  }

  Future<List<int>> getHourlyClickDensity(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final events = await _isar.telemetryEvents
        .filter()
        .nameEqualTo('click')
        .timestampBetween(start, end)
        .findAll();
    final density = List.filled(24, 0);
    for (final e in events) {
      density[e.timestamp.hour]++;
    }
    return density;
  }
}
```

- [ ] **Step 1.9: Implement BlacklistRepository**

```dart
// lib/features/telemetry/data/repositories/blacklist_repository.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/blacklist_rule.dart';

const _kBlacklistKey = 'kero_blacklist_rules_v1';

class BlacklistRepository {
  final FlutterSecureStorage _storage;
  BlacklistRepository(this._storage);

  Future<List<BlacklistRule>> getRules() async {
    final raw = await _storage.read(key: _kBlacklistKey);
    if (raw == null || raw.isEmpty) return [];
    return BlacklistRule.listFromJson(raw);
  }

  Future<void> saveRules(List<BlacklistRule> rules) async {
    await _storage.write(key: _kBlacklistKey, value: BlacklistRule.listToJson(rules));
  }

  Future<void> addRule(BlacklistRule rule) async {
    final rules = await getRules();
    rules.removeWhere((r) => r.packageName == rule.packageName);
    rules.add(rule);
    await saveRules(rules);
  }

  Future<void> removeRule(String packageName) async {
    final rules = await getRules();
    rules.removeWhere((r) => r.packageName == packageName);
    await saveRules(rules);
  }

  Future<void> updateRule(BlacklistRule updated) async {
    final rules = await getRules();
    final idx = rules.indexWhere((r) => r.packageName == updated.packageName);
    if (idx >= 0) rules[idx] = updated;
    await saveRules(rules);
  }
}
```

- [ ] **Step 1.10: Commit**
```bash
git add lib/features/telemetry/data/ test/features/telemetry/repositories/
git commit -m "feat(telemetry): add data models and repositories for Phase 7"
```

---

## Task 2: Extend KeroSpacePlatformService (Dart + Kotlin)

**Files:**
- Modify: `lib/core/data/kero_space_platform_service.dart`
- Create: `android/app/src/main/kotlin/com/kero_space/kero_space/telemetry/BlacklistPreferencesStore.kt`
- Modify: `android/app/src/main/kotlin/com/kero_space/kero_space/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `pubspec.yaml`

- [ ] **Step 2.1: Add 3 new methods to KeroSpacePlatformService (Dart)**

In `lib/core/data/kero_space_platform_service.dart`, add inside the `KeroSpacePlatformService` class (keep existing `showOverlay`/`dismissOverlay`):

```dart
  /// Syncs blacklist rules to Kotlin EncryptedSharedPreferences.
  /// Call after every BlacklistRepository write.
  Future<void> setBlacklistRules(String rulesJson) async {
    await _methodChannel.invokeMethod('setBlacklistRules', {'rulesJson': rulesJson});
  }

  /// Start or stop an agent. agentId: 'accessibility' | 'usage_guard' | 'screen_event' | 'wake_word'
  Future<void> toggleAgent(String agentId, bool enabled) async {
    await _methodChannel.invokeMethod('toggleAgent', {'agentId': agentId, 'enabled': enabled});
  }

  /// Returns current enabled status of all 4 agents.
  Future<Map<String, bool>> getAgentStatuses() async {
    final result = await _methodChannel.invokeMapMethod<String, bool>('getAgentStatuses');
    return result ?? {};
  }
```

- [ ] **Step 2.2: Create BlacklistPreferencesStore.kt**

```kotlin
// android/app/src/main/kotlin/com/kero_space/kero_space/telemetry/BlacklistPreferencesStore.kt
package com.kero_space.kero_space.telemetry

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONArray

object BlacklistPreferencesStore {
    private const val PREFS_FILE = "kero_blacklist_prefs"
    private const val KEY_RULES = "blacklist_rules_json"

    private fun getPrefs(context: Context) = EncryptedSharedPreferences.create(
        context, PREFS_FILE,
        MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveRulesJson(context: Context, json: String) =
        getPrefs(context).edit().putString(KEY_RULES, json).apply()

    fun getRulesJson(context: Context): String =
        getPrefs(context).getString(KEY_RULES, "[]") ?: "[]"

    fun getBlockedPackages(context: Context): Set<String> {
        val arr = JSONArray(getRulesJson(context))
        return (0 until arr.length()).map { arr.getJSONObject(it).getString("packageName") }.toSet()
    }
}
```

- [ ] **Step 2.3: Add 3 MethodChannel handlers in MainActivity.kt**

Find the `when(call.method)` block inside `configureFlutterEngine` and add:

```kotlin
"setBlacklistRules" -> {
    val rulesJson = call.argument<String>("rulesJson") ?: "[]"
    BlacklistPreferencesStore.saveRulesJson(this, rulesJson)
    result.success(null)
}
"toggleAgent" -> {
    val agentId = call.argument<String>("agentId") ?: ""
    val enabled = call.argument<Boolean>("enabled") ?: false
    handleAgentToggle(agentId, enabled)
    result.success(null)
}
"getAgentStatuses" -> {
    result.success(buildAgentStatusMap())
}
```

Add helper methods to `MainActivity`:
```kotlin
private fun handleAgentToggle(agentId: String, enabled: Boolean) {
    when (agentId) {
        "wake_word" -> {
            val intent = Intent(this, WakeWordService::class.java)
            if (enabled) startForegroundService(intent) else stopService(intent)
        }
        "usage_guard" -> {
            if (enabled) {
                WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                    "UsageStatsWorker", ExistingPeriodicWorkPolicy.KEEP,
                    PeriodicWorkRequestBuilder<UsageStatsWorker>(15, TimeUnit.MINUTES).build()
                )
            } else {
                WorkManager.getInstance(this).cancelUniqueWork("UsageStatsWorker")
            }
        }
        "screen_event" -> {
            sendBroadcast(Intent("kero_space.TOGGLE_SCREEN_RECEIVER").putExtra("enabled", enabled))
        }
        "accessibility" -> {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }
    }
}

private fun buildAgentStatusMap(): Map<String, Boolean> = mapOf(
    "accessibility" to isAccessibilityEnabled(),
    "usage_guard" to isUsageGuardScheduled(),
    "screen_event" to isServiceRunning(KeroSpaceForegroundService::class.java),
    "wake_word" to isServiceRunning(WakeWordService::class.java),
)

private fun isServiceRunning(cls: Class<*>): Boolean {
    @Suppress("DEPRECATION")
    return (getSystemService(ACTIVITY_SERVICE) as ActivityManager)
        .getRunningServices(Int.MAX_VALUE).any { it.service.className == cls.name }
}

private fun isAccessibilityEnabled(): Boolean {
    val svc = "$packageName/${KeroSpaceAccessibilityService::class.java.name}"
    return (Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: "").contains(svc)
}

private fun isUsageGuardScheduled(): Boolean =
    WorkManager.getInstance(this).getWorkInfosForUniqueWork("UsageStatsWorker").get()
        .any { it.state == WorkInfo.State.ENQUEUED || it.state == WorkInfo.State.RUNNING }
```

- [ ] **Step 2.4: Add `QUERY_ALL_PACKAGES` to AndroidManifest.xml**

```xml
<!-- After existing <uses-permission> entries: -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"
    tools:ignore="QueryAllPackagesPermission" />
```

- [ ] **Step 2.5: Add device_apps to pubspec.yaml**

```yaml
# Under dependencies:
  device_apps: ^2.2.0
```

```powershell
rtk flutter pub get
```

- [ ] **Step 2.6: Commit**
```bash
git add lib/core/data/kero_space_platform_service.dart \
        android/ pubspec.yaml pubspec.lock
git commit -m "feat(telemetry): extend platform service — blacklist sync + agent toggle"
```

---

## Task 3: TelemetryBloc

**Files:**
- Create: `lib/features/telemetry/presentation/bloc/telemetry_event.dart`
- Create: `lib/features/telemetry/presentation/bloc/telemetry_state.dart`
- Create: `lib/features/telemetry/presentation/bloc/telemetry_bloc.dart`
- Test: `test/features/telemetry/bloc/telemetry_bloc_test.dart`

- [ ] **Step 3.1: Create telemetry_event.dart**

```dart
// lib/features/telemetry/presentation/bloc/telemetry_event.dart
import 'package:equatable/equatable.dart';
import '../../data/models/blacklist_rule.dart';

abstract class TelemetryEvent extends Equatable {
  const TelemetryEvent();
  @override List<Object?> get props => [];
}

class LoadTelemetryDashboard extends TelemetryEvent {}
class LoadUnlockHeatmap extends TelemetryEvent {
  final DateTime weekStart;
  const LoadUnlockHeatmap(this.weekStart);
  @override List<Object?> get props => [weekStart];
}
class LoadBlockerStats extends TelemetryEvent {}
class LoadClickLogs extends TelemetryEvent {
  final String? packageFilter;
  final DateTime? from;
  final DateTime? to;
  final int page;
  const LoadClickLogs({this.packageFilter, this.from, this.to, this.page = 0});
  @override List<Object?> get props => [packageFilter, from, to, page];
}
class LoadBlacklist extends TelemetryEvent {}
class AddBlacklistRule extends TelemetryEvent {
  final BlacklistRule rule;
  const AddBlacklistRule(this.rule);
  @override List<Object?> get props => [rule];
}
class RemoveBlacklistRule extends TelemetryEvent {
  final String packageName;
  const RemoveBlacklistRule(this.packageName);
  @override List<Object?> get props => [packageName];
}
class UpdateBlacklistRule extends TelemetryEvent {
  final BlacklistRule rule;
  const UpdateBlacklistRule(this.rule);
  @override List<Object?> get props => [rule];
}
class ToggleAgent extends TelemetryEvent {
  final String agentId;
  final bool enabled;
  const ToggleAgent(this.agentId, this.enabled);
  @override List<Object?> get props => [agentId, enabled];
}
class RefreshAgentStatuses extends TelemetryEvent {}
```

- [ ] **Step 3.2: Create telemetry_state.dart**

```dart
// lib/features/telemetry/presentation/bloc/telemetry_state.dart
import 'package:equatable/equatable.dart';
import 'package:kero_space/features/telemetry/data/models/telemetry_collections.dart';
import '../../data/models/blacklist_rule.dart';
import '../../data/models/blocker_stat.dart';

enum TelemetryStatus { initial, loading, success, failure }

class TelemetryState extends Equatable {
  final TelemetryStatus status;
  final String? errorMessage;
  final int todayScreenTimeMs;
  final List<AppUsageRecord> todayTopApps;
  final List<(DateTime, int)> weeklyScreenTime;
  final List<List<int>> unlockHeatmap;          // 7×24
  final List<BlockerStat> blockerStats;
  final List<TelemetryEvent> clickLogs;
  final int clickLogPage;
  final bool clickLogHasMore;
  final List<BlacklistRule> blacklistRules;
  final Map<String, bool> agentStatuses;

  const TelemetryState({
    this.status = TelemetryStatus.initial,
    this.errorMessage,
    this.todayScreenTimeMs = 0,
    this.todayTopApps = const [],
    this.weeklyScreenTime = const [],
    this.unlockHeatmap = const [],
    this.blockerStats = const [],
    this.clickLogs = const [],
    this.clickLogPage = 0,
    this.clickLogHasMore = true,
    this.blacklistRules = const [],
    this.agentStatuses = const {},
  });

  TelemetryState copyWith({
    TelemetryStatus? status,
    String? errorMessage,
    int? todayScreenTimeMs,
    List<AppUsageRecord>? todayTopApps,
    List<(DateTime, int)>? weeklyScreenTime,
    List<List<int>>? unlockHeatmap,
    List<BlockerStat>? blockerStats,
    List<TelemetryEvent>? clickLogs,
    int? clickLogPage,
    bool? clickLogHasMore,
    List<BlacklistRule>? blacklistRules,
    Map<String, bool>? agentStatuses,
  }) => TelemetryState(
    status: status ?? this.status,
    errorMessage: errorMessage,
    todayScreenTimeMs: todayScreenTimeMs ?? this.todayScreenTimeMs,
    todayTopApps: todayTopApps ?? this.todayTopApps,
    weeklyScreenTime: weeklyScreenTime ?? this.weeklyScreenTime,
    unlockHeatmap: unlockHeatmap ?? this.unlockHeatmap,
    blockerStats: blockerStats ?? this.blockerStats,
    clickLogs: clickLogs ?? this.clickLogs,
    clickLogPage: clickLogPage ?? this.clickLogPage,
    clickLogHasMore: clickLogHasMore ?? this.clickLogHasMore,
    blacklistRules: blacklistRules ?? this.blacklistRules,
    agentStatuses: agentStatuses ?? this.agentStatuses,
  );

  @override
  List<Object?> get props => [
    status, errorMessage, todayScreenTimeMs, todayTopApps,
    weeklyScreenTime, unlockHeatmap, blockerStats, clickLogs,
    clickLogPage, clickLogHasMore, blacklistRules, agentStatuses,
  ];
}
```

- [ ] **Step 3.3: Write failing TelemetryBloc test**

```dart
// test/features/telemetry/bloc/telemetry_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kero_space/features/telemetry/data/repositories/screen_event_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/app_usage_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/click_log_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/blacklist_repository.dart';
import 'package:kero_space/core/data/kero_space_platform_service.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_state.dart';

@GenerateMocks([
  ScreenEventRepository, AppUsageRepository, ClickLogRepository,
  BlacklistRepository, KeroSpacePlatformService,
])
void main() {
  late MockScreenEventRepository screenRepo;
  late MockAppUsageRepository usageRepo;
  late MockClickLogRepository clickRepo;
  late MockBlacklistRepository blacklistRepo;
  late MockKeroSpacePlatformService platformService;

  setUp(() {
    screenRepo = MockScreenEventRepository();
    usageRepo = MockAppUsageRepository();
    clickRepo = MockClickLogRepository();
    blacklistRepo = MockBlacklistRepository();
    platformService = MockKeroSpacePlatformService();
    when(screenRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
    when(usageRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
  });

  blocTest<TelemetryBloc, TelemetryState>(
    'LoadTelemetryDashboard emits loading then success with todayScreenTimeMs',
    build: () {
      when(screenRepo.getTotalScreenTimeMs(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => 3600000);
      when(usageRepo.getTodayUsage()).thenAnswer((_) async => []);
      when(usageRepo.getWeeklyScreenTimeTotals()).thenAnswer((_) async => []);
      when(blacklistRepo.getRules()).thenAnswer((_) async => []);
      when(platformService.getAgentStatuses()).thenAnswer((_) async => {});
      return TelemetryBloc(screenRepo, usageRepo, clickRepo, blacklistRepo, platformService);
    },
    act: (bloc) => bloc.add(LoadTelemetryDashboard()),
    expect: () => [
      isA<TelemetryState>().having((s) => s.status, 'status', TelemetryStatus.loading),
      isA<TelemetryState>()
        .having((s) => s.status, 'status', TelemetryStatus.success)
        .having((s) => s.todayScreenTimeMs, 'screenTime', 3600000),
    ],
  );
}
```

- [ ] **Step 3.4: Run test — verify FAIL**
```powershell
rtk flutter pub run build_runner build --delete-conflicting-outputs
rtk flutter test test/features/telemetry/bloc/telemetry_bloc_test.dart -v
```
Expected: FAIL — `TelemetryBloc` not found.

- [ ] **Step 3.5: Implement TelemetryBloc**

```dart
// lib/features/telemetry/presentation/bloc/telemetry_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../data/repositories/screen_event_repository.dart';
import '../../data/repositories/app_usage_repository.dart';
import '../../data/repositories/click_log_repository.dart';
import '../../data/repositories/blacklist_repository.dart';
import '../../data/models/blacklist_rule.dart';
import '../../../../core/data/kero_space_platform_service.dart';
import 'telemetry_event.dart';
import 'telemetry_state.dart';

class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  final ScreenEventRepository _screenRepo;
  final AppUsageRepository _usageRepo;
  final ClickLogRepository _clickRepo;
  final BlacklistRepository _blacklistRepo;
  final KeroSpacePlatformService _platform;
  StreamSubscription<void>? _screenSub;
  StreamSubscription<void>? _usageSub;

  TelemetryBloc(this._screenRepo, this._usageRepo, this._clickRepo,
      this._blacklistRepo, this._platform)
      : super(const TelemetryState()) {
    on<LoadTelemetryDashboard>(_onLoadDashboard);
    on<LoadUnlockHeatmap>(_onLoadHeatmap);
    on<LoadBlockerStats>(_onLoadBlockerStats);
    on<LoadClickLogs>(_onLoadClickLogs);
    on<LoadBlacklist>(_onLoadBlacklist);
    on<AddBlacklistRule>(_onAddRule);
    on<RemoveBlacklistRule>(_onRemoveRule);
    on<UpdateBlacklistRule>(_onUpdateRule);
    on<ToggleAgent>(_onToggleAgent);
    on<RefreshAgentStatuses>(_onRefreshStatuses);

    _screenSub = _screenRepo.watchChanges().listen((_) => add(LoadTelemetryDashboard()));
    _usageSub = _usageRepo.watchChanges().listen((_) => add(LoadTelemetryDashboard()));
  }

  Future<void> _onLoadDashboard(
      LoadTelemetryDashboard event, Emitter<TelemetryState> emit) async {
    emit(state.copyWith(status: TelemetryStatus.loading));
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final screenTimeMs = await _screenRepo.getTotalScreenTimeMs(from: startOfDay, to: now);
      final topApps = (await _usageRepo.getTodayUsage()).take(8).toList();
      final weekly = await _usageRepo.getWeeklyScreenTimeTotals();
      final rules = await _blacklistRepo.getRules();
      final statuses = await _platform.getAgentStatuses();
      emit(state.copyWith(
        status: TelemetryStatus.success,
        todayScreenTimeMs: screenTimeMs,
        todayTopApps: topApps,
        weeklyScreenTime: weekly,
        blacklistRules: rules,
        agentStatuses: statuses,
      ));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadHeatmap(
      LoadUnlockHeatmap event, Emitter<TelemetryState> emit) async {
    final heatmap = await _screenRepo.getUnlockHeatmap(weekStart: event.weekStart);
    emit(state.copyWith(unlockHeatmap: heatmap));
  }

  Future<void> _onLoadBlockerStats(
      LoadBlockerStats event, Emitter<TelemetryState> emit) async {
    // Blocker stats aggregate from TelemetryEvent name='blocker_decision'
    // Populated when overlay is shown/dismissed — empty until overlays fire
    emit(state.copyWith(blockerStats: const []));
  }

  Future<void> _onLoadClickLogs(
      LoadClickLogs event, Emitter<TelemetryState> emit) async {
    final logs = await _clickRepo.getClickLogs(
      packageName: event.packageFilter,
      from: event.from,
      to: event.to,
      page: event.page,
    );
    final allLogs = event.page == 0 ? logs : [...state.clickLogs, ...logs];
    emit(state.copyWith(
      clickLogs: allLogs,
      clickLogPage: event.page,
      clickLogHasMore: logs.length == ClickLogRepository.pageSize,
    ));
  }

  Future<void> _onLoadBlacklist(
      LoadBlacklist event, Emitter<TelemetryState> emit) async {
    final rules = await _blacklistRepo.getRules();
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onAddRule(AddBlacklistRule event, Emitter<TelemetryState> emit) async {
    await _blacklistRepo.addRule(event.rule);
    final rules = await _blacklistRepo.getRules();
    await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onRemoveRule(
      RemoveBlacklistRule event, Emitter<TelemetryState> emit) async {
    await _blacklistRepo.removeRule(event.packageName);
    final rules = await _blacklistRepo.getRules();
    await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onUpdateRule(
      UpdateBlacklistRule event, Emitter<TelemetryState> emit) async {
    await _blacklistRepo.updateRule(event.rule);
    final rules = await _blacklistRepo.getRules();
    await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onToggleAgent(ToggleAgent event, Emitter<TelemetryState> emit) async {
    await _platform.toggleAgent(event.agentId, event.enabled);
    final statuses = await _platform.getAgentStatuses();
    emit(state.copyWith(agentStatuses: statuses));
  }

  Future<void> _onRefreshStatuses(
      RefreshAgentStatuses event, Emitter<TelemetryState> emit) async {
    final statuses = await _platform.getAgentStatuses();
    emit(state.copyWith(agentStatuses: statuses));
  }

  @override
  Future<void> close() {
    _screenSub?.cancel();
    _usageSub?.cancel();
    return super.close();
  }
}
```

- [ ] **Step 3.6: Run test — verify PASS**
```powershell
rtk flutter test test/features/telemetry/bloc/telemetry_bloc_test.dart -v
```

- [ ] **Step 3.7: Commit**
```bash
git add lib/features/telemetry/presentation/bloc/ test/features/telemetry/bloc/
git commit -m "feat(telemetry): implement TelemetryBloc with all events and state"
```

---

## Task 4: DI + Router Wiring

**Files:**
- Modify: `lib/core/di/injection.dart`
- Modify: `lib/core/router.dart`

- [ ] **Step 4.1: Add TelemetryBloc to injection.dart**

Add imports:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kero_space/core/data/kero_space_platform_service.dart';
import 'package:kero_space/features/telemetry/data/repositories/screen_event_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/app_usage_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/click_log_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/blacklist_repository.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';
```

Add registrations inside `setupLocator()`:
```dart
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<KeroSpacePlatformService>(() => KeroSpacePlatformService());
  getIt.registerLazySingleton<ScreenEventRepository>(
      () => ScreenEventRepository(IsarService.instance));
  getIt.registerLazySingleton<AppUsageRepository>(
      () => AppUsageRepository(IsarService.instance));
  getIt.registerLazySingleton<ClickLogRepository>(
      () => ClickLogRepository(IsarService.instance));
  getIt.registerLazySingleton<BlacklistRepository>(
      () => BlacklistRepository(getIt<FlutterSecureStorage>()));
  getIt.registerFactory<TelemetryBloc>(() => TelemetryBloc(
    getIt<ScreenEventRepository>(),
    getIt<AppUsageRepository>(),
    getIt<ClickLogRepository>(),
    getIt<BlacklistRepository>(),
    getIt<KeroSpacePlatformService>(),
  ));
```

- [ ] **Step 4.2: Replace /telemetry placeholder in router.dart**

Add imports:
```dart
import '../features/telemetry/presentation/screens/telemetry_home_screen.dart';
import '../features/telemetry/presentation/bloc/telemetry_bloc.dart';
import '../features/telemetry/presentation/bloc/telemetry_event.dart';
```

Replace the placeholder route:
```dart
    GoRoute(
      path: '/telemetry',
      builder: (context, state) => BlocProvider(
        create: (_) => GetIt.I<TelemetryBloc>()..add(LoadTelemetryDashboard()),
        child: const TelemetryHomeScreen(),
      ),
    ),
```

- [ ] **Step 4.3: flutter analyze**
```powershell
rtk flutter analyze
```
Expected: No errors.

- [ ] **Step 4.4: Commit**
```bash
git add lib/core/di/injection.dart lib/core/router.dart
git commit -m "feat(telemetry): wire TelemetryBloc into DI and router"
```

---

## Task 5: HeatmapPainter Widget

**Files:**
- Create: `lib/features/telemetry/presentation/widgets/heatmap_painter.dart`
- Test: `test/features/telemetry/widgets/heatmap_painter_test.dart`

- [ ] **Step 5.1: Write failing widget test**

```dart
// test/features/telemetry/widgets/heatmap_painter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/telemetry/presentation/widgets/heatmap_painter.dart';

void main() {
  testWidgets('HeatmapGrid renders without error', (tester) async {
    final matrix = List.generate(1, (_) => List.generate(24, (h) => h == 9 ? 3 : 0));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 480, height: 28,
          child: HeatmapGrid(matrix: matrix, onCellTap: (_, __) {}),
        ),
      ),
    ));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
```

- [ ] **Step 5.2: Run test — verify FAIL**
```powershell
rtk flutter test test/features/telemetry/widgets/heatmap_painter_test.dart -v
```

- [ ] **Step 5.3: Implement HeatmapGrid + _HeatmapPainter**

```dart
// lib/features/telemetry/presentation/widgets/heatmap_painter.dart
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class HeatmapGrid extends StatelessWidget {
  final List<List<int>> matrix; // [row][col] = count
  final void Function(int row, int col) onCellTap;

  const HeatmapGrid({super.key, required this.matrix, required this.onCellTap});

  @override
  Widget build(BuildContext context) {
    final maxVal = matrix.expand((r) => r).fold(1, (a, b) => a > b ? a : b);
    return LayoutBuilder(builder: (context, constraints) {
      final cellW = constraints.maxWidth / (matrix.isEmpty ? 1 : matrix[0].length);
      final cellH = constraints.maxHeight / matrix.length;
      return GestureDetector(
        onTapUp: (d) {
          final col = (d.localPosition.dx / cellW).floor().clamp(0, (matrix[0].length) - 1);
          final row = (d.localPosition.dy / cellH).floor().clamp(0, matrix.length - 1);
          onCellTap(row, col);
        },
        child: CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _HeatmapPainter(matrix: matrix, maxVal: maxVal, cellW: cellW, cellH: cellH),
        ),
      );
    });
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<List<int>> matrix;
  final int maxVal;
  final double cellW;
  final double cellH;

  const _HeatmapPainter(
      {required this.matrix, required this.maxVal, required this.cellW, required this.cellH});

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < matrix.length; r++) {
      for (int c = 0; c < matrix[r].length; c++) {
        final intensity = maxVal > 0 ? matrix[r][c] / maxVal : 0.0;
        final color = Color.lerp(AppTheme.bgElevated, AppTheme.accentCyan, intensity)!;
        final rect = Rect.fromLTWH(c * cellW + 1, r * cellH + 1, cellW - 2, cellH - 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) => old.matrix != matrix || old.maxVal != maxVal;
}
```

- [ ] **Step 5.4: Run test — verify PASS**
```powershell
rtk flutter test test/features/telemetry/widgets/heatmap_painter_test.dart -v
```

- [ ] **Step 5.5: Commit**
```bash
git add lib/features/telemetry/presentation/widgets/heatmap_painter.dart \
        test/features/telemetry/widgets/
git commit -m "feat(telemetry): implement HeatmapPainter CustomPainter widget"
```

---

## Task 6: UI Widgets (AgentToggleCard + BypassPuzzleDialog + ResistanceRateCard)

**Files:**
- Create: `lib/features/telemetry/presentation/widgets/agent_toggle_card.dart`
- Create: `lib/features/telemetry/presentation/widgets/bypass_puzzle_dialog.dart`
- Create: `lib/features/telemetry/presentation/widgets/resistance_rate_card.dart`
- Create: `lib/features/telemetry/presentation/widgets/app_usage_tile.dart`
- Create: `lib/features/telemetry/presentation/widgets/click_log_entry_tile.dart`

- [ ] **Step 6.1: Create agent_toggle_card.dart**

```dart
// lib/features/telemetry/presentation/widgets/agent_toggle_card.dart
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class AgentToggleCard extends StatelessWidget {
  final String agentId;
  final String label;
  final IconData icon;
  final String statusSummary;
  final bool isEnabled;
  final void Function(bool) onToggle;

  const AgentToggleCard({
    super.key, required this.agentId, required this.label, required this.icon,
    required this.statusSummary, required this.isEnabled, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppTheme.accentCyan.withOpacity(0.5) : AppTheme.bgElevated,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: isEnabled ? AppTheme.accentCyan : AppTheme.textDisabled, size: 20),
            const Spacer(),
            Switch.adaptive(value: isEnabled, onChanged: onToggle, activeColor: AppTheme.accentCyan),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                statusSummary,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6.2: Create bypass_puzzle_dialog.dart**

```dart
// lib/features/telemetry/presentation/widgets/bypass_puzzle_dialog.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class BypassPuzzleDialog extends StatefulWidget {
  const BypassPuzzleDialog({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showDialog<bool>(context: context, barrierDismissible: false,
          builder: (_) => const BypassPuzzleDialog()) ?? false;

  @override
  State<BypassPuzzleDialog> createState() => _State();
}

class _State extends State<BypassPuzzleDialog> {
  late final int _a, _b, _answer;
  bool _revealed = true;
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = rng.nextInt(9) + 1;
    _b = rng.nextInt(9) + 1;
    _answer = _a + _b;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  void _submit() {
    if (int.tryParse(_ctrl.text.trim()) == _answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Wrong answer — try again');
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, color: AppTheme.accentRose, size: 36),
          const SizedBox(height: 12),
          Text('Emergency Bypass', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Solve the puzzle. This action is logged.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _revealed ? '$_a + $_b = ?' : '? + ? = ?',
              key: ValueKey(_revealed),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: _revealed ? AppTheme.accentGold : AppTheme.textDisabled,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24),
            decoration: InputDecoration(
              hintText: 'Answer',
              errorText: _error,
              filled: true,
              fillColor: AppTheme.bgElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRose),
              child: const Text('Bypass'),
            )),
          ]),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 6.3: Create resistance_rate_card.dart**

```dart
// lib/features/telemetry/presentation/widgets/resistance_rate_card.dart
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import '../../data/models/blocker_stat.dart';

class ResistanceRateCard extends StatelessWidget {
  final BlockerStat stat;
  const ResistanceRateCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final pct = (stat.resistanceRate * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stat.packageName.split('.').last, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(children: [
          Text('$pct%', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppTheme.accentMint)),
          const SizedBox(width: 12),
          Expanded(child: Text(
            'You resisted the urge $pct% of the time',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary),
          )),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: stat.resistanceRate, backgroundColor: AppTheme.bgElevated,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentMint),
          minHeight: 6, borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 6),
        Text('${stat.blockedAttempts} blocked · ${stat.grantedOverrides} overridden',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
      ]),
    );
  }
}
```

- [ ] **Step 6.4: Create app_usage_tile.dart**

```dart
// lib/features/telemetry/presentation/widgets/app_usage_tile.dart
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class AppUsageTile extends StatelessWidget {
  final Application app;
  final int? foregroundMs;
  final bool isBlacklisted;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const AppUsageTile({
    super.key, required this.app, this.foregroundMs,
    required this.isBlacklisted, required this.onAdd, required this.onRemove,
  });

  String _fmt(int ms) {
    final h = ms ~/ 3600000; final m = (ms % 3600000) ~/ 60000;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final icon = app is ApplicationWithIcon ? (app as ApplicationWithIcon).icon : null;
    return ListTile(
      leading: icon != null
          ? Image.memory(icon, width: 40, height: 40)
          : const Icon(Icons.android, color: AppTheme.accentCyan),
      title: Text(app.appName, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: foregroundMs != null && foregroundMs! > 0
          ? Text('Used ${_fmt(foregroundMs!)} today',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary))
          : null,
      trailing: isBlacklisted
          ? IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accentRose), onPressed: onRemove)
          : IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentCyan), onPressed: onAdd),
    );
  }
}
```

- [ ] **Step 6.5: Create click_log_entry_tile.dart**

```dart
// lib/features/telemetry/presentation/widgets/click_log_entry_tile.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/telemetry/data/models/telemetry_collections.dart';

class ClickLogEntryTile extends StatelessWidget {
  final TelemetryEvent event;
  const ClickLogEntryTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    try { data = jsonDecode(event.dataJson) as Map<String, dynamic>; } catch (_) {}
    final pkg = (data['packageName'] as String? ?? 'unknown').split('.').last;
    final viewId = data['viewId'] as String? ?? '';
    final time = '${event.timestamp.hour.toString().padLeft(2,'0')}:${event.timestamp.minute.toString().padLeft(2,'0')}';
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.touch_app, color: AppTheme.accentCyan, size: 18),
      ),
      title: Text(pkg, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: viewId.isNotEmpty
          ? Text(viewId, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(time, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
    );
  }
}
```

- [ ] **Step 6.6: Commit**
```bash
git add lib/features/telemetry/presentation/widgets/
git commit -m "feat(telemetry): add all UI widget components"
```

---

## Task 7: All 6 Screens

**Files:**
- Create: `lib/features/telemetry/presentation/screens/screen_time_overview_screen.dart`
- Create: `lib/features/telemetry/presentation/screens/unlock_heatmap_screen.dart`
- Create: `lib/features/telemetry/presentation/screens/blocker_effectiveness_screen.dart`
- Create: `lib/features/telemetry/presentation/screens/blacklist_management_screen.dart`
- Create: `lib/features/telemetry/presentation/screens/click_log_browser_screen.dart`
- Create: `lib/features/telemetry/presentation/screens/omniscient_control_center_screen.dart`
- Create: `lib/features/telemetry/presentation/screens/telemetry_home_screen.dart`

- [ ] **Step 7.1: Create screen_time_overview_screen.dart**

```dart
// lib/features/telemetry/presentation/screens/screen_time_overview_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_state.dart';

class ScreenTimeOverviewScreen extends StatelessWidget {
  const ScreenTimeOverviewScreen({super.key});

  String _fmt(int ms) {
    final h = ms ~/ 3600000; final m = (ms % 3600000) ~/ 60000;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      if (state.status == TelemetryStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero metric
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Today's Screen Time",
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(_fmt(state.todayScreenTimeMs),
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(color: AppTheme.accentCyan)),
            ]),
          ),
          const SizedBox(height: 24),
          Text('7-Day Trend', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: _WeeklyChart(data: state.weeklyScreenTime)),
          const SizedBox(height: 24),
          Text('App Breakdown Today', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          SizedBox(height: 260, child: _AppPieChart(apps: state.todayTopApps)),
        ]),
      );
    });
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<(DateTime, int)> data;
  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data yet', style: TextStyle(color: AppTheme.textSecondary)));
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.$2 / 60000.0)).toList();
    return LineChart(LineChartData(
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: AppTheme.accentCyan, barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: AppTheme.accentCyan.withOpacity(0.1)),
      )],
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
      ),
    ));
  }
}

class _AppPieChart extends StatelessWidget {
  final List apps;
  const _AppPieChart({required this.apps});
  static const _colors = [
    AppTheme.accentCyan, AppTheme.accentMint, AppTheme.accentGold, AppTheme.accentViolet,
    AppTheme.accentRose, Color(0xFF30D158), Color(0xFF64D2FF), Color(0xFFFFD60A),
  ];

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const Center(child: Text('No usage data yet', style: TextStyle(color: AppTheme.textSecondary)));
    final sections = apps.asMap().entries.map((e) => PieChartSectionData(
      value: (e.value.foregroundMs as int).toDouble(),
      color: _colors[e.key % _colors.length],
      radius: 80, showTitle: false,
    )).toList();
    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 50, sectionsSpace: 2));
  }
}
```

- [ ] **Step 7.2: Create unlock_heatmap_screen.dart**

```dart
// lib/features/telemetry/presentation/screens/unlock_heatmap_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/heatmap_painter.dart';

class UnlockHeatmapScreen extends StatefulWidget {
  const UnlockHeatmapScreen({super.key});
  @override State<UnlockHeatmapScreen> createState() => _State();
}

class _State extends State<UnlockHeatmapScreen> {
  late DateTime _weekStart;
  int? _selDay, _selHour;
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(mon.year, mon.month, mon.day);
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TelemetryBloc>().add(LoadUnlockHeatmap(_weekStart)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Unlock Patterns', style: Theme.of(context).textTheme.titleMedium),
          Text('Tap a cell to see unlock count for that hour.',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          // hour labels
          Row(children: [
            const SizedBox(width: 36),
            ...List.generate(24, (h) => Expanded(child: h % 6 == 0
                ? Text('${h}h', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9))
                : const SizedBox())),
          ]),
          const SizedBox(height: 4),
          ...List.generate(7, (d) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(width: 36, child: Text(_days[d],
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
              Expanded(child: SizedBox(height: 28,
                child: state.unlockHeatmap.isEmpty
                    ? Container(color: AppTheme.bgElevated)
                    : HeatmapGrid(
                        matrix: [state.unlockHeatmap[d]],
                        onCellTap: (_, col) => setState(() { _selDay = d; _selHour = col; }),
                      ),
              )),
            ]),
          )),
          const SizedBox(height: 16),
          if (_selDay != null && _selHour != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.lock_open, color: AppTheme.accentCyan),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_days[_selDay!]} at ${_selHour.toString().padLeft(2,'0')}:00',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text(
                    '${state.unlockHeatmap.isNotEmpty ? state.unlockHeatmap[_selDay!][_selHour!] : 0} unlocks',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary),
                  ),
                ]),
              ]),
            ),
        ]),
      );
    });
  }
}
```

- [ ] **Step 7.3: Create blocker_effectiveness_screen.dart**

```dart
// lib/features/telemetry/presentation/screens/blocker_effectiveness_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_state.dart';
import '../bloc/telemetry_bloc.dart';
import '../widgets/resistance_rate_card.dart';

class BlockerEffectivenessScreen extends StatelessWidget {
  const BlockerEffectivenessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      if (state.blockerStats.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.shield_outlined, color: AppTheme.accentMint, size: 64),
          const SizedBox(height: 16),
          Text('No blocker events yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Add apps to the blacklist to start tracking.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
        ]));
      }
      return ListView(padding: const EdgeInsets.all(16), children: [
        Text('Resistance Report', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Last 7 days — how well you resisted mindless scrolling',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        ...state.blockerStats.map((s) => ResistanceRateCard(stat: s)),
      ]);
    });
  }
}
```

- [ ] **Step 7.4: Create blacklist_management_screen.dart**

```dart
// lib/features/telemetry/presentation/screens/blacklist_management_screen.dart
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../../data/models/blacklist_rule.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/app_usage_tile.dart';

class BlacklistManagementScreen extends StatefulWidget {
  const BlacklistManagementScreen({super.key});
  @override State<BlacklistManagementScreen> createState() => _State();
}

class _State extends State<BlacklistManagementScreen> {
  List<Application> _apps = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<TelemetryBloc>().add(LoadBlacklist());
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true, includeSystemApps: false, onlyAppsWithLaunchIntent: true);
    if (mounted) setState(() { _apps = apps; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      final blacklisted = state.blacklistRules.map((r) => r.packageName).toSet();
      final usageMap = {for (final r in state.todayTopApps) r.packageName: r.foregroundMs};
      final filtered = _apps
          .where((a) => _query.isEmpty || a.appName.toLowerCase().contains(_query.toLowerCase()))
          .toList()
        ..sort((a, b) => (usageMap[b.packageName] ?? 0).compareTo(usageMap[a.packageName] ?? 0));

      return Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search apps...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true, fillColor: AppTheme.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        _loading
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : Expanded(child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final app = filtered[i];
                  return AppUsageTile(
                    app: app, foregroundMs: usageMap[app.packageName],
                    isBlacklisted: blacklisted.contains(app.packageName),
                    onAdd: () => context.read<TelemetryBloc>().add(
                      AddBlacklistRule(BlacklistRule(packageName: app.packageName, decisionBreakSeconds: 30))),
                    onRemove: () => context.read<TelemetryBloc>().add(RemoveBlacklistRule(app.packageName)),
                  );
                },
              )),
      ]);
    });
  }
}
```

- [ ] **Step 7.5: Create click_log_browser_screen.dart**

```dart
// lib/features/telemetry/presentation/screens/click_log_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/click_log_entry_tile.dart';

class ClickLogBrowserScreen extends StatefulWidget {
  const ClickLogBrowserScreen({super.key});
  @override State<ClickLogBrowserScreen> createState() => _State();
}

class _State extends State<ClickLogBrowserScreen> {
  final _scroll = ScrollController();
  String? _pkgFilter;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    context.read<TelemetryBloc>().add(const LoadClickLogs());
  }

  void _onScroll() {
    final s = context.read<TelemetryBloc>().state;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200
        && s.clickLogHasMore && s.status != TelemetryStatus.loading) {
      context.read<TelemetryBloc>().add(LoadClickLogs(packageFilter: _pkgFilter, page: s.clickLogPage + 1));
    }
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onSubmitted: (v) {
              setState(() => _pkgFilter = v.isEmpty ? null : v);
              context.read<TelemetryBloc>().add(LoadClickLogs(packageFilter: _pkgFilter));
            },
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filter by package...',
              prefixIcon: const Icon(Icons.filter_list, color: AppTheme.textSecondary),
              filled: true, fillColor: AppTheme.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(child: state.clickLogs.isEmpty
            ? const Center(child: Text('No click logs yet', style: TextStyle(color: AppTheme.textSecondary)))
            : ListView.builder(
                controller: _scroll,
                itemCount: state.clickLogs.length + (state.clickLogHasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == state.clickLogs.length) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  }
                  return ClickLogEntryTile(event: state.clickLogs[i]);
                },
              )),
      ]);
    });
  }
}
```

- [ ] **Step 7.6: Create omniscient_control_center_screen.dart**

```dart
// lib/features/telemetry/presentation/screens/omniscient_control_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/agent_toggle_card.dart';
import '../widgets/bypass_puzzle_dialog.dart';

class OmniscientControlCenterScreen extends StatefulWidget {
  const OmniscientControlCenterScreen({super.key});
  @override State<OmniscientControlCenterScreen> createState() => _State();
}

class _State extends State<OmniscientControlCenterScreen> {
  static const _agents = [
    ('accessibility', 'Scrolling Blocker', Icons.block, 'Intercepts blacklisted app launches'),
    ('usage_guard',   'Usage Guard',       Icons.bar_chart, 'Tracks foreground time every 15 min'),
    ('screen_event',  'Screen Monitor',    Icons.phone_android, 'Logs wake, sleep & unlock events'),
    ('wake_word',     'Wake Word',         Icons.mic, 'Listens for "Hey Kero" — fully offline'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TelemetryBloc>().add(RefreshAgentStatuses()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Agent Control Center', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Toggle agents and configure blocker rules.',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
            itemCount: _agents.length,
            itemBuilder: (context, i) {
              final (id, label, icon, summary) = _agents[i];
              return AgentToggleCard(
                agentId: id, label: label, icon: icon, statusSummary: summary,
                isEnabled: state.agentStatuses[id] ?? false,
                onToggle: (v) => context.read<TelemetryBloc>().add(ToggleAgent(id, v)),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Emergency Override', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentRose.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRose),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bypass Blocker', style: Theme.of(context).textTheme.headlineMedium),
                Text('Solve a math puzzle to bypass. Event is logged.',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
              ])),
              TextButton(
                onPressed: () async {
                  final solved = await BypassPuzzleDialog.show(context);
                  if (solved && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bypass granted. Logged.')));
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentRose),
                child: const Text('Override'),
              ),
            ]),
          ),
        ]),
      );
    });
  }
}
```

- [ ] **Step 7.7: Create telemetry_home_screen.dart**

```dart
// lib/features/telemetry/presentation/screens/telemetry_home_screen.dart
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import 'screen_time_overview_screen.dart';
import 'unlock_heatmap_screen.dart';
import 'blocker_effectiveness_screen.dart';
import 'blacklist_management_screen.dart';
import 'click_log_browser_screen.dart';
import 'omniscient_control_center_screen.dart';

class TelemetryHomeScreen extends StatefulWidget {
  const TelemetryHomeScreen({super.key});
  @override State<TelemetryHomeScreen> createState() => _State();
}

class _State extends State<TelemetryHomeScreen> {
  int _idx = 0;

  static const _tabs = [
    (Icons.phone_android, 'Overview'),
    (Icons.grid_view,     'Heatmap'),
    (Icons.shield,        'Resistance'),
    (Icons.block,         'Blacklist'),
    (Icons.touch_app,     'Clicks'),
    (Icons.settings,      'Control'),
  ];

  static const _screens = [
    ScreenTimeOverviewScreen(),
    UnlockHeatmapScreen(),
    BlockerEffectivenessScreen(),
    BlacklistManagementScreen(),
    ClickLogBrowserScreen(),
    OmniscientControlCenterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        title: Text(_tabs[_idx].$2,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: _screens[_idx],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.bgSurface,
        indicatorColor: AppTheme.accentCyan.withOpacity(0.2),
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: _tabs.map((t) => NavigationDestination(
          icon: Icon(t.$1, color: AppTheme.textSecondary),
          selectedIcon: Icon(t.$1, color: AppTheme.accentCyan),
          label: t.$2,
        )).toList(),
      ),
    );
  }
}
```

- [ ] **Step 7.8: Commit all screens**
```bash
git add lib/features/telemetry/presentation/screens/
git commit -m "feat(telemetry): implement all 6 screens + tab host — Phase 7 UI complete"
```

---

## Task 8: Static Analysis + Build Verification

- [ ] **Step 8.1: Run flutter analyze**
```powershell
rtk flutter analyze
```
Expected: No errors. Fix any before proceeding.

- [ ] **Step 8.2: Run all telemetry tests**
```powershell
rtk flutter test test/features/telemetry/ -v
```
Expected: All PASS.

- [ ] **Step 8.3: Run debug APK build**
```powershell
rtk flutter build apk --debug
```
Expected: BUILD SUCCESSFUL. Fix Kotlin errors before proceeding.

- [ ] **Step 8.4: Mark Phase 7 tasks complete in tasks.md**

Update `tasks.md` — mark tasks 7.1–7.7 as `[x]`.

- [ ] **Step 8.5: Final commit**
```bash
git add tasks.md
git commit -m "chore: mark Phase 7 Telemetry Dashboard complete ✓"
```

---

## Phase 7 Definition of Done

- [ ] `TelemetryBloc` aggregates data from all 3 repositories
- [ ] Screen Time shows hero metric + 7-day trend line + app pie chart
- [ ] Unlock Heatmap 7×24 grid renders; tapping cell shows detail panel
- [ ] Blocker Effectiveness shows resistance rate with plain-English subtitle
- [ ] Blacklist manager lists installed apps sorted by usage; add/remove syncs to Kotlin via MethodChannel
- [ ] Click Log Browser paginates (50 records/page) with infinite scroll
- [ ] Control Center shows 2×2 agent cards with status summaries + bypass puzzle
- [ ] `flutter analyze` — no errors
- [ ] All telemetry tests pass
- [ ] Debug APK builds successfully
