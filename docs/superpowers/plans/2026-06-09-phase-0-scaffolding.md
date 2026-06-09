# Phase 0: Project Scaffolding & DevOps Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the monorepo package structure, CI pipeline, and Docker backend skeleton so every subsequent phase delivers into a working system.

**Architecture:** Clean Architecture pattern. `AppTheme` handles styling centrally. Docker Compose coordinates local backend services.

**Tech Stack:** Flutter 3.x, flutter_bloc, isar, go_router, Docker, Postgres, Caddy, GitHub Actions.

---

### Task 1: Package Structure Setup

**Files:**
- Create: `lib/core/.keep`
- Create: `lib/features/telemetry/.keep`
- Create: `lib/features/productivity/.keep`
- Create: `lib/features/health/.keep`
- Create: `lib/features/finance/.keep`
- Create: `lib/features/church/.keep`
- Create: `lib/features/voice/.keep`
- Create: `lib/shared/widgets/.keep`

- [ ] **Step 1: Create directories and .keep files**

```bash
mkdir -p lib/core lib/features/telemetry lib/features/productivity lib/features/health lib/features/finance lib/features/church lib/features/voice lib/shared/widgets
touch lib/core/.keep lib/features/telemetry/.keep lib/features/productivity/.keep lib/features/health/.keep lib/features/finance/.keep lib/features/church/.keep lib/features/voice/.keep lib/shared/widgets/.keep
```

- [ ] **Step 2: Commit changes**

```bash
git add lib/core lib/features lib/shared
git commit -m "chore: setup feature package structure"
```

### Task 2: Configure Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

```bash
flutter pub add flutter_bloc equatable isar isar_flutter_libs fl_chart rive flutter_secure_storage dio get_it injectable health go_router freezed_annotation json_annotation
flutter pub add dev:build_runner dev:freezed dev:json_serializable dev:injectable_generator dev:isar_generator
```

- [ ] **Step 2: Verify dependencies resolution**

Run: `flutter pub get`
Expected: Resolves without conflicts.

- [ ] **Step 3: Commit changes**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add core dependencies for Kero Space"
```

### Task 3: Implement AppTheme

**Files:**
- Create: `lib/core/app_theme.dart`

- [ ] **Step 1: Create the AppTheme class**

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSurface = Color(0xFF1C1C1E);
  static const Color bgElevated = Color(0xFF2C2C2E);
  static const Color bgOverlay = Color(0x99000000);

  static const Color accentPrimary = Color(0xFFFFFFFF);
  static const Color accentCyan = Color(0xFF0A84FF);
  static const Color accentMint = Color(0xFF32D74B);
  static const Color accentRose = Color(0xFFFF453A);
  static const Color accentGold = Color(0xFFFF9F0A);
  static const Color accentViolet = Color(0xFFBF5AF2);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99EBEBF5);
  static const Color textDisabled = Color(0x4DEBEBF5);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: accentPrimary,
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentCyan,
        surface: bgSurface,
        error: accentRose,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: textPrimary),
        labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/app_theme.dart
git commit -m "feat(theme): implement unified AppTheme"
```

### Task 4: Configure go_router & Stub Screens

**Files:**
- Create: `lib/core/router.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create router and stub screens**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Placeholder for $title')),
    );
  }
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderScreen(title: 'Home / Dashboard'),
    ),
    GoRoute(
      path: '/productivity',
      builder: (context, state) => const PlaceholderScreen(title: 'Productivity'),
    ),
    GoRoute(
      path: '/health',
      builder: (context, state) => const PlaceholderScreen(title: 'Health'),
    ),
    GoRoute(
      path: '/finance',
      builder: (context, state) => const PlaceholderScreen(title: 'Finance'),
    ),
    GoRoute(
      path: '/church',
      builder: (context, state) => const PlaceholderScreen(title: 'Church'),
    ),
    GoRoute(
      path: '/telemetry',
      builder: (context, state) => const PlaceholderScreen(title: 'Telemetry'),
    ),
  ],
);
```

- [ ] **Step 2: Integrate into main.dart**

```dart
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/router.dart';

void main() {
  runApp(const KeroSpaceApp());
}

class KeroSpaceApp extends StatelessWidget {
  const KeroSpaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kero Space',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router.dart lib/main.dart
git commit -m "feat(routing): setup go_router and stub screens"
```

### Task 5: Docker Backend Skeleton

**Files:**
- Create: `docker/docker-compose.yml`
- Create: `docker/postgres/init.sql`
- Create: `docker/caddy/Caddyfile`
- Create: `backend/pubspec.yaml`
- Create: `backend/bin/server.dart`

- [ ] **Step 1: Setup Docker Compose**

`docker/docker-compose.yml`:
```yaml
version: '3.8'
services:
  kero-space-api:
    build: ../backend
    ports:
      - "8080:8080"
    depends_on:
      - kero-space-postgres
      - kero-space-redis

  kero-space-postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: kero
      POSTGRES_PASSWORD: space_password
      POSTGRES_DB: kero_space
    ports:
      - "5432:5432"
    volumes:
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql

  kero-space-redis:
    image: redis:7
    ports:
      - "6379:6379"

  kero-space-caddy:
    image: caddy:2
    ports:
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
    depends_on:
      - kero-space-api
```

`docker/postgres/init.sql`:
```sql
CREATE TABLE IF NOT EXISTS health_check (
  id SERIAL PRIMARY KEY,
  status VARCHAR(50) NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

`docker/caddy/Caddyfile`:
```
localhost {
    tls internal
    reverse_proxy kero-space-api:8080
}
```

- [ ] **Step 2: Dart API Stub**

```bash
mkdir backend
cd backend
dart create -t server-shelf . --force
```

Modify `backend/bin/server.dart`:
```dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main(List<String> args) async {
  final router = Router()
    ..get('/health', (Request req) => Response.ok('200 OK'));

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
```

- [ ] **Step 3: Test backend build**

Run: `cd docker && docker-compose config`
Expected: Validates correctly.

- [ ] **Step 4: Commit**

```bash
git add docker/ backend/
git commit -m "feat(backend): setup docker compose skeleton and dart shelf stub"
```

### Task 6: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create CI pipeline**

```yaml
name: Kero Space CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  flutter-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

- [ ] **Step 2: Commit**

```bash
git add .github/
git commit -m "ci: add GitHub Actions for flutter test and analyze"
```

### Task 7: Android Permissions

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add permissions to AndroidManifest.xml**

Inside `<manifest>` tag, before `<application>`:

```xml
    <uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE" tools:ignore="ProtectedPermissions" xmlns:tools="http://schemas.android.com/tools"/>
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" xmlns:tools="http://schemas.android.com/tools"/>
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

- [ ] **Step 2: Test Android build**

Run: `flutter build apk --debug`
Expected: Successful build.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore(android): declare necessary native permissions"
```
