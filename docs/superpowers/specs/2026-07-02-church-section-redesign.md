# Church Section Redesign — Design Spec

## Overview
Complete overhaul of the Church feature in Kero Space. Fixes broken logic, eliminates duplicate models, redesigns all 4 tabs to match the app's premium dark theme, and integrates the feature with the rest of the app (voice, home card, notifications, health).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CHURCH MODULE                             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ChurchScreen (Scaffold + AppBar + TabBar)           │   │
│  │  ├── CopticTab       (NEW)                           │   │
│  │  ├── AttendanceTab   (redesigned)                    │   │
│  │  ├── MinistryTab     (redesigned)                    │   │
│  │  └── ConfessionTab   (polished)                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  BLoCs                                                │   │
│  │  ├── ChurchBloc     → attendances, tasks, streak     │   │
│  │  ├── ConfessionBloc → encrypted session management   │   │
│  │  └── CopticBloc     → Coptic calendar data (NEW)     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Services                                             │   │
│  │  ├── ChurchRepository     → Isar CRUD                │   │
│  │  ├── CopticCalendarService → date/feast/fast calc    │   │
│  │  ├── YouVersionService    → Bible API integration    │   │
│  │  ├── ConfessionCryptoService → AES-256-GCM           │   │
│  │  ├── EncryptedConfessionsRepo → encrypted Isar       │   │
│  │  └── ChurchNotificationService → reminders           │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Data Layer

### Model Consolidation

**MassAttendance** (single source of truth)
```dart
@Collection()
class MassAttendance {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late DateTime date;           // normalized to midnight
  List<ServiceType> services;   // multiple per day
  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();
}

enum ServiceType { liturgy, vespers, midnightPraise, divineLiturgy, other }
```

**MinistryTask** (immutable with copyWith)
```dart
@Collection()
class MinistryTask {
  Id id = Isar.autoIncrement;
  late String title;
  String? description;
  @enumerated late MinistryTaskStatus status;
  DateTime? deadline;
  int priority;  // 1-5
  String? assignedTo;
  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();
  
  MinistryTask copyWith({...}) => ...;
}

enum MinistryTaskStatus { todo, inProgress, done }
```

**CopticDayInfo** (computed, not persisted)
```dart
class CopticDayInfo {
  final int copticYear;
  final int copticMonth;
  final int copticDay;
  final String monthName;
  final String? feastName;
  final String? feastDescription;
  final FastingStatus fastStatus;
  final String? seasonName;
  final List<ScriptureReference> readings;
  final List<UpcomingFeast> upcomingFeasts;
}

enum FastingStatus { none, strict, fishAllowed, vegan }

class ScriptureReference {
  final String book;
  final String chapter;
  final String verses;
  final String displayName;  // e.g., "John 14:26-31"
}

class UpcomingFeast {
  final String name;
  final DateTime date;
  final int daysRemaining;
  final bool isMajor;
}
```

### Deleted Files
- `church_collections.dart` + `.g.dart` — consolidated into `mass_attendance.dart`

### Repository Changes
- `ChurchRepository.getAttendancesByDateRange(start, end)` — for monthly stats
- `ChurchRepository.getStreak()` — returns current + best streak
- `ChurchRepository.getMonthlyStats()` — count by service type

### New Services

**CopticCalendarService** (pure Dart, no deps)
- `computeToday()` → `CopticDayInfo`
- `computeForDate(DateTime)` → `CopticDayInfo`
- Algorithm: Coptic year = Gregorian year - 283 (Sept-Dec) or - 284 (Jan-Aug)
- Months: Tout, Baba, Hator, Kiahk, Toba, Amshir, Baramhat, Baramouda, Bashans, Paona, Epep, Mesra, Nasie
- Feast mapping: lookup table for fixed feasts + computed for movable feasts (Pascal computation)
- Fasting: lookup by date range (Great Lent, Apostles', Nativity, St. Mary, Jonah, Wed/Fri)

**YouVersionService**
- Requires App Key from platform.youversion.com
- `getPassageText(ScriptureReference)` → `String` (scripture text)
- `getPassageUrl(ScriptureReference)` → `String` (deep link)
- Falls back gracefully if no API key configured

## UI Design

### ChurchScreen (Shell)
- `Scaffold` with `AppBar` + `TabBar` (4 tabs)
- No nested Scaffolds in child tabs
- Matches `HealthDashboardScreen` pattern

### Tab 1: CopticTab (NEW)
- `CustomScrollView` with `SliverList`
- **Zone 1**: Header card — Coptic date, season, fasting status
- **Zone 2**: Today's feast — name + description
- **Zone 3**: Today's readings — scripture references, tappable to open YouVersion
- **Zone 4**: Upcoming feasts — horizontal scrollable cards with countdown
- **Zone 5**: Fast status — progress bar if in fasting period
- States: Loading (skeleton), Loaded, Error (InlineErrorWidget + retry)

### Tab 2: AttendanceTab (Redesigned)
- `CustomScrollView` with `SliverList`
- **Zone 1**: Streak hero card — animated ring (reuse `RadialProgressPainter`), current streak, best streak, this month count
- **Zone 2**: Monthly stats — cards for each service type count
- **Zone 3**: Contribution grid — fixed version using AppTheme tokens
- **Zone 4**: Recent activity — list of recent marks with delete/undo
- Mark flow: Bottom sheet with service type selector → optimistic update → haptic feedback
- States: Loading (skeleton), Loaded, Error (InlineErrorWidget + retry), Empty

### Tab 3: MinistryTab (Redesigned)
- Horizontal `Row` with 3 equal columns (Todo / In Progress / Done)
- Each column: scrollable list of task cards
- Task card: priority badge, title, description, deadline chip, assigned to
- Tap card → bottom sheet with full details + edit
- Add task: FAB → bottom sheet form
- States: Loading (3 column skeletons), Loaded, Error, Empty

### Tab 4: ConfessionTab (Polished)
- Same auth + encrypted log flow
- Passphrase strength indicator
- Proper theme token usage
- No nested Scaffold
- Proper go_router back navigation

## Cross-Feature Integration

### Home Screen
- Real streak from `ChurchBloc.state.currentStreak`
- Shows "MASS TODAY ✅" if today is marked

### Voice Commands
- "mark mass [today/yesterday]" → `MarkAttendanceEvent`
- "mark liturgy" → same
- "open church" → navigate to `/church`
- "how's my streak" → read streak aloud

### Notifications
- Sunday liturgy reminder at 7:00 AM
- Fasting period start/end notifications
- Uses existing `church_notification_service.dart`

### Health Integration
- Fasting day badge on Health dashboard
- Meal logging reminder during fasting periods

### Keyboard Shortcut
- `Ctrl+Shift+M` → marks liturgy (already exists, keep)

## Error Handling & Loading States
- **Loading**: Shimmer skeleton (reuse `HealthSkeleton` pattern)
- **Error**: `InlineErrorWidget` with retry button
- **Empty**: Graceful empty state with icon + message
- **Retry**: Dispatches `LoadChurchData()` or equivalent

## Implementation Order
1. Data layer: models, repository, services
2. BLoCs: ChurchBloc fixes, CopticBloc
3. UI: ChurchScreen shell, CopticTab, AttendanceTab, MinistryTab, ConfessionTab
4. Cross-feature: Home card, voice, notifications, health
5. Cleanup: Delete duplicate files, remove dead code