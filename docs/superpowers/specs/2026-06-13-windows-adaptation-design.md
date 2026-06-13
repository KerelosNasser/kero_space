# Windows Desktop Adaptation — Design Spec
**Date:** 2026-06-13  
**Phase:** 9  
**Status:** Approved (multi-agent review passed)

---

## Overview

Adapt Kero Space for Windows desktop by introducing an adaptive navigation shell (`StatefulShellRoute`), a Windows-native process watcher via Dart FFI (`user32.dll`), system-wide keyboard shortcuts at the `MaterialApp` level, `window_manager` with a system tray icon, and Docker `localhost:8443` connectivity as the Windows backend target.

---

## Decisions Log

| Decision | Chosen | Rationale |
|----------|--------|-----------|
| Navigation shell | `StatefulShellRoute` (GoRouter 14+) | Automatically tracks `currentIndex`; avoids manual uri-to-index mapping |
| Mobile nav | `BottomNavigationBar` | Existing familiar mobile pattern |
| Desktop nav | `NavigationRail(labelType: all)` | Always-visible labels for discoverability |
| Breakpoint | `MediaQuery.sizeOf(context).width >= 800` | Standard Flutter desktop breakpoint |
| Detail routes (health sub-routes, note editor) | Outside `StatefulShellRoute` | Render full-screen without nav chrome |
| Keyboard shortcuts | `Shortcuts` + `Actions` at `MaterialApp` level | Fire regardless of focused widget (not blocked by TextFields) |
| Windows FFI | `user32.dll` — `GetForegroundWindow` + `GetWindowTextW` | Minimal, no third-party package; wide-char, UTF-16 with try/finally memory guard |
| Timer pause | Pause on `onWindowMinimize`, resume on `onWindowFocus` | Prevents battery drain when minimized to tray |
| Platform isolation | `WindowManagerService` never imported outside `lib/core/platform/windows/` | Prevents Android crash from unconditionally-linked Windows packages |
| Docker (Windows) | `localhost:8443` default, configurable IP in SharedPreferences | Same machine first, home server fallback |

---

## Architecture

```
StatefulShellRoute (go_router)
  └── AppShell widget
       ├── [width < 800px] → Scaffold(bottomNavigationBar: AdaptiveBottomNav, body: child)
       └── [width ≥ 800px] → Scaffold(body: Row(AdaptiveNavRail, Expanded(child)))

Detail routes (outside shell):
  /health/config, /health/search, /health/log, /note_editor

WindowManagerService (Windows only, lib/core/platform/windows/)
  ├── window_manager: hidden title bar + WM_DELETE intercept → minimize to tray
  └── SystemTray: quick-action menu with shortcut hints

ProcessWatcherBloc (Windows only, lib/core/platform/windows/)
  ├── FFI: user32.dll → GetForegroundWindow + GetWindowTextW (UTF-16, try/finally free)
  ├── Timer.periodic(5s) — paused on minimize, resumed on focus
  └── States: ProcessWatcherInitial | ProcessChanged(title) | ProcessWatcherUnavailable

Shortcuts + Actions (MaterialApp level — system-wide)
  Ctrl+N        → navigate to /productivity (new task)
  Ctrl+Shift+M  → ChurchBloc(MarkAttendanceToday)
  Ctrl+L        → navigate to /health/search
  Ctrl+/        → VoiceBloc(StartListeningEvent)

DockerConnectivity (SyncWorker enhancement)
  Windows → try localhost:8443 → fallback configuredIp:8443
  Android → existing server IP logic (unchanged)
```

---

## Component Specifications

### StatefulShellRoute

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
    AppShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/productivity', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/health', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/finance', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/church', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/telemetry', ...)]),
  ],
)
// Detail routes at top level, outside StatefulShellRoute:
GoRoute(path: '/health/config', ...)
GoRoute(path: '/health/search', ...)
GoRoute(path: '/health/log', ...)
GoRoute(path: '/note_editor', ...)
```

### AppShell

```dart
bool isDesktop = MediaQuery.sizeOf(context).width >= 800;
final destinations = [
  (icon: Icons.home_rounded, label: 'Home'),
  (icon: Icons.task_alt, label: 'Productivity'),
  (icon: Icons.favorite_rounded, label: 'Health'),
  (icon: Icons.account_balance_wallet, label: 'Finance'),
  (icon: Icons.church, label: 'Church'),
  (icon: Icons.bar_chart, label: 'Telemetry'),
];

if (isDesktop) → Row(
  NavigationRail(
    labelType: NavigationRailLabelType.all,
    selectedIndex: navigationShell.currentIndex,
    onDestinationSelected: (i) => navigationShell.goBranch(i),
    destinations: destinations.map(NavigationRailDestination).toList(),
  ),
  Expanded(child: navigationShell),
)
if (mobile) → Scaffold(
  body: navigationShell,
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: navigationShell.currentIndex,
    onTap: (i) => navigationShell.goBranch(i),
    items: destinations.map(BottomNavigationBarItem).toList(),
  ),
)
```

### ProcessWatcherBloc FFI

```dart
// lib/core/platform/windows/process_watcher_bloc.dart
final user32 = DynamicLibrary.open('user32.dll');
final _getForegroundWindow = user32.lookupFunction<
  IntPtr Function(), int Function()>('GetForegroundWindow');
final _getWindowText = user32.lookupFunction<
  Int32 Function(IntPtr, Pointer<Uint16>, Int32),
  int Function(int, Pointer<Uint16>, int)>('GetWindowTextW');

void _poll() {
  final buf = calloc<Uint16>(256);
  try {
    final hwnd = _getForegroundWindow();
    _getWindowText(hwnd, buf, 256);
    final title = buf.cast<Utf16>().toDartString();
    if (title != state.currentTitle) emit(ProcessChanged(title));
  } catch (e) {
    emit(ProcessWatcherUnavailable(e.toString()));
  } finally {
    calloc.free(buf);
  }
}
```

### WindowManagerService

```dart
// lib/core/platform/windows/window_manager_service.dart
class WindowManagerService {
  static Future<void> init() async {
    await windowManager.ensureInitialized();
    windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    windowManager.setPreventClose(true); // intercept close → minimize to tray

    final tray = SystemTray();
    await tray.initSystemTray(iconPath: 'assets/icons/tray.ico');
    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Open Kero Space', onClicked: (_) => windowManager.show()),
      MenuItemLabel(label: 'New Task (Ctrl+N)', onClicked: (_) => router.go('/productivity')),
      MenuItemLabel(label: 'Mark Mass (Ctrl+Shift+M)', onClicked: (_) => getIt<ChurchBloc>().add(MarkAttendanceToday())),
      MenuSeparator(),
      MenuItemLabel(label: 'Exit', onClicked: (_) => windowManager.destroy()),
    ]);
    await tray.setContextMenu(menu);
  }
}
```

### Keyboard Shortcuts (MaterialApp level)

```dart
// Registered via MaterialApp's shortcuts/actions parameters
shortcuts: {
  const SingleActivator(LogicalKeyboardKey.keyN, control: true):
      NavigateToIntent('/productivity'),
  const SingleActivator(LogicalKeyboardKey.keyM, control: true, shift: true):
      MarkAttendanceIntent(),
  const SingleActivator(LogicalKeyboardKey.keyL, control: true):
      NavigateToIntent('/health/search'),
  const SingleActivator(LogicalKeyboardKey.slash, control: true):
      StartVoiceIntent(),
},
actions: {
  NavigateToIntent: NavigateToAction(router),
  MarkAttendanceIntent: MarkAttendanceAction(churchBloc),
  StartVoiceIntent: StartVoiceAction(voiceBloc),
},
```

---

## Platform Isolation Rules

1. `window_manager` and `system_tray` are in `pubspec.yaml` (cannot be conditional)
2. Their code ONLY lives in `lib/core/platform/windows/window_manager_service.dart`
3. `main.dart` calls: `if (Platform.isWindows) await WindowManagerService.init();`
4. No other file may import from `lib/core/platform/windows/`
5. `ProcessWatcherBloc` is registered in GetIt only inside `if (Platform.isWindows)` block

---

## File Structure

```
lib/
  core/
    platform/
      platform_guard.dart                  ← isDesktop / isMobile helpers
      windows/
        process_watcher_bloc.dart          ← FFI + Timer state machine
        process_watcher_event.dart
        process_watcher_state.dart
        window_manager_service.dart        ← window_manager + tray
  shared/
    widgets/
      app_shell.dart                       ← adaptive nav wrapper
      adaptive_nav_rail.dart               ← desktop NavigationRail
      adaptive_bottom_nav.dart             ← mobile BottomNavigationBar
  main.dart                                ← platform-guarded init

pubspec.yaml additions:
  window_manager: ^0.3.8
  system_tray: ^2.0.3
  ffi: ^2.1.0
```

---

## Error Handling

| Failure | Behavior |
|---------|----------|
| user32.dll load failure | ProcessWatcherBloc emits `ProcessWatcherUnavailable`, timer stops |
| FFI call throws | try/finally ensures calloc.free, emits `ProcessWatcherUnavailable` |
| window_manager init failure | Logged, skipped — standard window chrome used |
| Tray icon asset missing | Caught, tray silently disabled |
| StatefulShellRoute branch out of range | GoRouter default redirect to `/` |
| Shortcut Intent on Android | Actions registered but never invoked (no physical keyboard events) |

---

## Docker Connectivity (Windows)

```dart
// In SyncWorker, Platform.isWindows detection:
final baseUrl = Platform.isWindows
  ? (prefs.getString('docker_ip') ?? 'localhost')
  : (prefs.getString('server_ip') ?? '192.168.1.100');
final endpoint = 'https://$baseUrl:8443';
```

No settings UI in Phase 9 V1 — `localhost` default. Configuration UI is Phase 10.

---

## Definition of Done

- App launches on Windows without crash
- Bottom nav visible on Android/mobile viewport; NavigationRail on ≥800px window
- All 6 destinations navigate correctly; detail routes (health sub-routes, note editor) render full-screen
- Keyboard shortcuts fire from all app states (including while a TextField is focused)
- Window minimizes to tray on close; tray menu reopens app
- ProcessWatcherBloc starts polling on Windows, logs active window title changes to console
- `flutter analyze` passes clean
- `flutter build apk --debug` succeeds (zero Android regressions)
- `flutter build windows --debug` succeeds
