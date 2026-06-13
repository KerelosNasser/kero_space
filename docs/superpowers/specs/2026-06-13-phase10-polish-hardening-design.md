# Phase 10 — Polish, Hardening & Production Readiness

**Date:** 2026-06-13  
**Status:** Approved  
**Scope:** Final polish pass before v1.0. Covers UX refinement, global error handling, security hardening, data export, backup scripts, and personal-device release packaging.

---

## 1. Goals

1. Make the app feel finished and trustworthy to a daily user.
2. Eliminate silent failures — every error must reach the user in a proportionate way.
3. Verify the security model holds before any data accumulates.
4. Produce installable, signed builds for Android (APK) and Windows (MSIX).

---

## 2. Onboarding — Progressive Disclosure

### Philosophy
No permission wall on first launch. The app opens directly to the Home screen. Permissions are requested lazily the first time the feature that needs them is accessed.

### PermissionRepository
A single `lib/core/permissions/permission_repository.dart` encapsulates all permission checks using the `permission_handler` package. No feature screen interacts with platform channels directly.

```dart
class PermissionRepository {
  Future<bool> hasAccessibilityService();
  Future<bool> hasUsageStats();
  Future<bool> hasNotificationListener();
  Future<bool> hasRecordAudio();
  Future<bool> hasBatteryOptimizationExemption();
  Future<void> requestRecordAudio();
  Future<void> openAccessibilitySettings();
  Future<void> openUsageStatsSettings();
  Future<void> openNotificationListenerSettings();
  Future<void> openBatteryOptimizationSettings();
}
```

### PermissionBanner
A shared `lib/core/permissions/permission_banner.dart` widget rendered at the top of each screen that requires a specific permission. It is shown only when the permission is missing, and dismissed automatically once granted (by listening to `AppLifecycleState.resumed`).

```
┌──────────────────────────────────────────────────────┐
│ ⚠  Kero needs Accessibility access to block          │
│    mindless scrolling.          [Enable →]  [✕]      │
└──────────────────────────────────────────────────────┘
```

### Permission → Feature Mapping

| Permission | Feature | Screen |
|---|---|---|
| Notification Listener | Finance notification parser | Finance Home |
| Accessibility Service | Scrolling Blocker | Settings Screen |
| Usage Stats | App usage tracking | Telemetry |
| Record Audio | Wake Word detection | Home / Voice |
| Battery Optimization | Foreground service persistence | Home |

### Battery Optimization
Checked on every cold start inside `main.dart`. If not exempted, a persistent `PermissionBanner` is shown on the Home screen until resolved.

---

## 3. Shimmer Loading Skeletons

### Package
Use `shimmer: ^3.0.0`. Already a widely used, zero-dependency Flutter package.

### Pattern
Each screen's BLoC emits three states:
- `Loading` → renders bespoke skeleton
- `Loaded` → fades in real content (200ms `AnimatedOpacity`)
- `Error` → renders `InlineErrorWidget`

### Per-Screen Skeletons

**Health Dashboard Skeleton** (`lib/shared/widgets/shimmer/health_skeleton.dart`)
- Circular progress ring placeholder (200px)
- 3 horizontal macro bar placeholders (protein/carbs/fat)
- 4 meal log row placeholders

**Finance Home Skeleton** (`lib/shared/widgets/shimmer/finance_skeleton.dart`)
- Large balance card placeholder
- 2 portfolio row placeholders
- 3 transaction list item placeholders

**Productivity Skeleton** (`lib/shared/widgets/shimmer/productivity_skeleton.dart`)
- 5 task list rows: checkbox circle + title line + tag chip

**Telemetry Skeleton** (`lib/shared/widgets/shimmer/telemetry_skeleton.dart`)
- Heatmap grid placeholder (7×24 cells)
- 3 stat card placeholders (unlock count, avg session, first unlock)

### Shared Primitives
`lib/shared/widgets/shimmer/shimmer_primitives.dart` exports:
- `ShimmerBox(width, height, borderRadius)` — rectangular placeholder
- `ShimmerCircle(diameter)` — circular placeholder
- `ShimmerLine(width)` — text-line placeholder

---

## 4. Error Handling — Two-Tier System

### Tier 1: Transient Errors → Snackbar

**AppErrorBloc** (`lib/core/error/app_error_bloc.dart`)
A global singleton BLoC registered in `GetIt`. Any BLoC in the feature tree dispatches:

```dart
getIt<AppErrorBloc>().add(TransientErrorOccurred(message: "Sync failed", retry: () => ...));
```

**ErrorSnackbarListener** (`lib/core/error/error_snackbar_listener.dart`)
Wraps the `MaterialApp.router` builder. Listens to `AppErrorBloc` and calls `ScaffoldMessenger.of(context).showSnackBar(...)`. Snackbar style: amber background, white text, optional "Retry" action button.

**Used for:**
- Sync failures (SyncWorker returns error)
- Network timeouts
- Non-critical BLoC operation failures

### Tier 2: Fatal Errors → Inline Error State

**InlineErrorWidget** (`lib/shared/widgets/inline_error_widget.dart`)
Rendered by `BlocBuilder` when a screen's BLoC emits `ErrorState`.

```
         ⚠️
   Something went wrong.
   Could not load your health data.
   
        [ Try Again ]
```

`onRetry` callback re-dispatches the original load event (e.g. `LoadDashboard()`).

**Used for:**
- Isar failed to open / query threw
- Critical data unavailable
- Permission permanently denied blocking core feature

### Error Severity Classification (enforced at BLoC level)

| Scenario | Tier |
|---|---|
| Sync outbox push failed | Transient (Snackbar) |
| Health Connect unavailable | Transient (Snackbar) |
| Isar write failed | Fatal (Inline) |
| Permission permanently denied | Fatal (Inline) |
| Finance notification parse error | Transient (Snackbar) |
| Voice transcription failed | Transient (Snackbar) |

---

## 5. Security

### 5.1 Automated Tests

**Confession Encryption Test** (`test/security/confession_encryption_test.dart`)
- Write a confession via `ConfessionCryptoService`.
- Read the raw bytes from the Isar collection field directly.
- Assert: raw bytes are NOT valid UTF-8 decodable to the original plaintext.

**TLS Rejection Test** (`test/security/tls_rejection_test.dart`)
- Configure the HTTP client with a mock bad certificate.
- Assert: request throws a `HandshakeException` / `SocketException`, not succeeds.

### 5.2 Manual Checklist (`docs/SECURITY_AUDIT.md`)

1. **Isar Inspector Review:** Open Isar Inspector, navigate to `Confession` collection, verify all `encryptedContent` values are Base64-encoded ciphertext, not readable text.
2. **Logcat PII grep:** Run `adb logcat | grep -i "confession\|password\|card\|email"` for 5 minutes of normal use. Expect zero matches.
3. **mitmproxy cert pinning:** Configure mitmproxy as proxy, open the app, attempt any sync. Expect all requests to fail with a certificate error, not succeed.

---

## 6. Data Export

**Location:** `lib/features/settings/`

A new `SettingsScreen` (accessible from the Home screen via a gear icon) with a single "Export My Data" option.

**What is exported:**
- Tasks (all)
- Meal logs (all)
- Transactions (all, non-PII only — amounts, categories, dates)
- Screen events (wake/sleep/unlock timestamps)
- Mass attendance records

**What is NOT exported:**
- Confessions (encrypted, excluded by design)
- Sync outbox queue

**Output:** Single `kero_space_export_YYYYMMDD.json` written to `getApplicationDocumentsDirectory()`. A Share sheet is opened immediately after so the user can copy it anywhere.

**Implementation:** `DataExportService` (`lib/features/settings/data/data_export_service.dart`) reads all collections sequentially and serializes to JSON using `jsonEncode`.

---

## 7. Docker Backup Script

**File:** `scripts/backup.sh`

```bash
#!/bin/bash
# Kero Space Backup Script
# Usage: ./backup.sh /path/to/external/drive

DEST="$1/kero_space_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DEST"

# PostgreSQL dump (Docker)
docker exec kero_space_postgres pg_dump -U kero kero_space > "$DEST/postgres.sql"

# Isar file (Android device via ADB)
adb pull /data/data/com.example.kero_space/files/ "$DEST/isar/"

echo "Backup complete: $DEST"
```

**Windows equivalent:** `scripts/backup.ps1` using the same logic with PowerShell syntax.

**Scheduling:** The `docs/BACKUP_SETUP.md` documents how to add this to Windows Task Scheduler or Linux cron.

---

## 8. Release Builds

### Android — Sideloaded APK

**ProGuard rules** (`android/app/proguard-rules.pro`):
- Keep all Isar-generated classes.
- Keep all Rive runtime classes.
- Keep all flutter_secure_storage JNI symbols.

**Keystore:** Generated once with `keytool`, stored at `~/.android/kero_space.jks`, never committed to the repo. `android/key.properties` references it (git-ignored).

**Build script:** `scripts/build_release.sh`
```bash
flutter build apk --release --obfuscate --split-debug-info=dist/debug-info/
cp build/app/outputs/flutter-apk/app-release.apk dist/kero_space_v1.0.apk
```

### Windows — MSIX Self-Signed

**Package:** `msix: ^3.16.7` added to `pubspec.yaml`.

**Self-signed cert:** Generated once with PowerShell:
```powershell
New-SelfSignedCertificate -Type Custom -Subject "CN=KeroSpace" `
  -KeyUsage DigitalSignature -FriendlyName "Kero Space" `
  -CertStoreLocation "Cert:\CurrentUser\My"
```
Installed to local machine trust store. Never committed.

**Build script:** `scripts/build_msix.ps1`
```powershell
flutter pub run msix:create
Copy-Item build/windows/x64/runner/Release/kero_space.msix dist/kero_space_v1.0.msix
```

---

## 9. New File Map

```
lib/
  core/
    error/
      app_error_bloc.dart
      app_error_event.dart
      app_error_state.dart
      error_snackbar_listener.dart
    permissions/
      permission_repository.dart
      permission_banner.dart
  shared/
    widgets/
      inline_error_widget.dart
      shimmer/
        shimmer_primitives.dart
        health_skeleton.dart
        finance_skeleton.dart
        productivity_skeleton.dart
        telemetry_skeleton.dart
  features/
    settings/
      presentation/
        screens/
          settings_screen.dart
      data/
        data_export_service.dart

test/
  security/
    confession_encryption_test.dart
    tls_rejection_test.dart

scripts/
  backup.sh
  backup.ps1
  build_release.sh
  build_msix.ps1

docs/
  SECURITY_AUDIT.md
  BACKUP_SETUP.md
```

---

## 10. Definition of Done

- All 4 shimmer skeletons render correctly on first load.
- `PermissionBanner` appears and resolves correctly for all 5 permissions.
- `AppErrorBloc` Snackbar fires on a simulated sync failure.
- `InlineErrorWidget` renders on a simulated Isar load failure.
- Both security tests pass with `flutter test`.
- `SECURITY_AUDIT.md` checklist is complete.
- `kero_space_export_YYYYMMDD.json` is produced by the export flow.
- `backup.sh` completes successfully against a running Docker container.
- `flutter build apk --release` produces a signed APK in `dist/`.
- `flutter pub run msix:create` produces a valid MSIX in `dist/`.
