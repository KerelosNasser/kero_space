# Kero Space - Session Handoff Context

## Context Snapshot
**Stack**: Flutter 3.x (Dart) | Windows OS
**Work type**: full-project / session-compaction
**Primary target**: `c:\projects\Flutter\kero_space` (Monorepo Root)
**Architecture**: Feature-first + BLoC
**State management**: `flutter_bloc`
**Router**: `go_router`
**Key deps (relevant)**: `isar`, `permission_handler`, `shimmer`, `get_it`, `integration_test`, `msix`
**Path aliases**: Standard `package:kero_space/...`
**Files indexed**:
  - `pubspec.yaml`
  - `tasks.md` (Master Roadmap)
  - `lib/core/permissions/*`
  - `lib/core/error/*`
  - `lib/shared/widgets/shimmer/*`
  - `scripts/*` (.sh & .ps1 builds/backups)
  - `docs/PERFORMANCE_AUDIT.md`, `SECURITY_AUDIT.md`, `BACKUP_SETUP.md`
  - `test/security/*` and `integration_test/app_test.dart`
**Generated files present**: yes (Isar adapters `.g.dart`, `build_runner` required)
**Open unknowns**: None. Windows C++ native assets build threw an environmental warning locally during testing, but Dart static analysis is fully clean.
**Windows path separator**: `\` (backslash) in PowerShell commands.

---

## 📦 Session State Summary

We have officially reached the end of the **Phase 10: Polish, Hardening & Production Readiness** roadmap. 

### Current State:
1. **Fully Implemented:** All 10 phases in `tasks.md` are completely marked as `[x]`. 
2. **Production-Ready:** The codebase is fortified with unified error handling (`AppErrorBloc`), progressive permission banners, beautiful shimmer loading screens, and robust security checks.
3. **Data Protection:** Offline data backup scripts (`backup.sh`/`.ps1`) and JSON export capabilities are integrated into `SettingsScreen`.
4. **CI/Build Tools:** Release build scripts (`build_release.sh` and `build_msix.ps1`) are ready to bundle the app.

### Where to pick up next time:
- If you alter any Isar models or Freezed classes, run:
  ```powershell
  rtk flutter pub run build_runner build --delete-conflicting-outputs
  ```
- To generate the final obfuscated `kero_space_release.apk` for your personal Android device:
  ```powershell
  ./scripts/build_release.sh
  ```
- To generate the Windows MSIX installer:
  ```powershell
  ./scripts/build_msix.ps1
  ```
