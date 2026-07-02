# Church Section Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the broken, disconnected Church section into a polished 4-tab spiritual hub with Coptic calendar, attendance tracking, ministry kanban, and encrypted confessions.

**Architecture:** Fix data layer first (consolidate duplicate models, correct streak logic, add immutability), then add new services (CopticCalendar, YouVersion), then rebuild all 4 tab UIs to match the app's dark theme, then wire cross-feature integrations (home card, voice, notifications).

**Tech Stack:** Flutter/Dart, Isar (local DB), BLoC (state management), flutter_quill (confession editor), YouVersion REST API (readings), go_router (navigation).

---

### Task 1: Fix Duplicate Models

**Files:**
- Modify: `lib/features/church/data/models/mass_attendance.dart`
- Delete: `lib/features/church/data/models/church_collections.dart`
- Delete: `lib/features/church/data/models/church_collections.g.dart`
- Modify: `lib/features/church/data/models/ministry_task.dart`
- Modify: `lib/features/church/data/repositories/church_repository.dart`
- Modify: `lib/features/church/data/models/confession_entry.dart` (if needed)

- [x] **Step 1: Rewrite MassAttendance model**

```dart
// lib/features/church/data/models/mass_attendance.dart
import 'package:isar/isar.dart';

part 'mass_attendance.g.dart';

enum ServiceType {
  liturgy,
  vespers,
  midnightPraise,
  divineLiturgy,
  other,
}

@Collection()
class MassAttendance {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  @enumerated
  List<ServiceType> services = [];

  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();
}
```

- [x] **Step 2: Rewrite MinistryTask with copyWith**

```dart
// lib/features/church/data/models/ministry_task.dart
import 'package:isar/isar.dart';

part 'ministry_task.g.dart';

enum MinistryTaskStatus { todo, inProgress, done }

@Collection()
class MinistryTask {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;

  @enumerated
  late MinistryTaskStatus status;

  DateTime? deadline;
  int priority = 3;
  String? assignedTo;

  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();

  MinistryTask copyWith({
    String? title,
    String? description,
    MinistryTaskStatus? status,
    DateTime? deadline,
    int? priority,
    String? assignedTo,
  }) {
    return MinistryTask()
      ..id = id
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..status = status ?? this.status
      ..deadline = deadline ?? this.deadline
      ..priority = priority ?? this.priority
      ..assignedTo = assignedTo ?? this.assignedTo
      ..serverId = serverId
      ..syncedAt = syncedAt
      ..locallyModifiedAt = DateTime.now();
  }
}
```

- [x] **Step 3: Update ChurchRepository with new methods**

```dart
// lib/features/church/data/repositories/church_repository.dart
class ChurchRepository {
  final Isar _isar;
  ChurchRepository(this._isar);

  Future<void> markAttendance(DateTime date, ServiceType type) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _isar.writeTxn(() async {
      final existing = await _isar.massAttendances
          .filter()
          .dateEqualTo(normalized)
          .findFirst();
      if (existing != null) {
        if (!existing.services.contains(type)) {
          existing.services = [...existing.services, type];
          await _isar.massAttendances.put(existing);
        }
      } else {
        final record = MassAttendance()
          ..date = normalized
          ..services = [type];
        await _isar.massAttendances.put(record);
      }
    });
  }

  Future<List<MassAttendance>> getAttendances() {
    return _isar.massAttendances.where().sortByDate().findAll();
  }

  Future<List<MassAttendance>> getAttendancesByDateRange(DateTime start, DateTime end) {
    return _isar.massAttendances
        .filter()
        .dateBetween(start, end)
        .sortByDate()
        .findAll();
  }

  Future<int> getStreak() async {
    final attendances = await _isar.massAttendances
        .where()
        .sortByDateDesc()
        .findAll();
    if (attendances.isEmpty) return 0;

    int streak = 0;
    DateTime expected = DateTime.now();
    expected = DateTime(expected.year, expected.month, expected.day);

    for (final att in attendances) {
      final attDate = DateTime(att.date.year, att.date.month, att.date.day);
      final diff = expected.difference(attDate).inDays;
      if (diff == 0) {
        if (streak == 0) streak = 1;
        expected = attDate.subtract(const Duration(days: 1));
      } else if (diff == 1) {
        streak++;
        expected = attDate.subtract(const Duration(days: 1));
      } else if (streak > 0) {
        break;
      }
    }
    return streak;
  }

  Future<int> getBestStreak() async {
    final attendances = await _isar.massAttendances
        .where()
        .sortByDateDesc()
        .findAll();
    if (attendances.isEmpty) return 0;

    final sorted = List<MassAttendance>.from(attendances)
      ..sort((a, b) => a.date.compareTo(b.date));

    int best = 0;
    int current = 0;
    DateTime? lastDate;

    for (final att in sorted) {
      final attDate = DateTime(att.date.year, att.date.month, att.date.day);
      if (lastDate == null) {
        current = 1;
      } else {
        final diff = attDate.difference(lastDate).inDays;
        if (diff == 1) {
          current++;
        } else {
          best = best > current ? best : current;
          current = 1;
        }
      }
      lastDate = attDate;
    }
    best = best > current ? best : current;
    return best;
  }

  Future<void> saveTask(MinistryTask task) async {
    await _isar.writeTxn(() async {
      await _isar.ministryTasks.put(task);
    });
  }

  Future<List<MinistryTask>> getTasks() async {
    return _isar.ministryTasks.where().findAll();
  }

  Future<void> deleteAttendance(DateTime date, ServiceType type) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _isar.writeTxn(() async {
      final existing = await _isar.massAttendances
          .filter()
          .dateEqualTo(normalized)
          .findFirst();
      if (existing != null) {
        existing.services = existing.services.where((s) => s != type).toList();
        if (existing.services.isEmpty) {
          await _isar.massAttendances.delete(existing.id);
        } else {
          await _isar.massAttendances.put(existing);
        }
      }
    });
  }
}
```

- [x] **Step 4: Delete duplicate church_collections.dart**

Delete `lib/features/church/data/models/church_collections.dart` and `church_collections.g.dart`. These are superseded by `mass_attendance.dart`.

- [x] **Step 5: Run build to regenerate Isar .g files**

Run: `flutter packages pub run build_runner build --delete-conflicting-outputs`

---

### Task 2: Create CopticCalendarService

**Files:**
- Create: `lib/features/church/data/services/coptic_calendar_service.dart`
- Create: `lib/features/church/data/models/coptic_day_info.dart`

- [x] **Step 1: Create CopticDayInfo model**

```dart
// lib/features/church/data/models/coptic_day_info.dart
enum FastingStatus { none, strict, fishAllowed, vegan }

class ScriptureReference {
  final String book;
  final String chapter;
  final String verses;
  final String displayName;

  const ScriptureReference({
    required this.book,
    required this.chapter,
    required this.verses,
    required this.displayName,
  });
}

class UpcomingFeast {
  final String name;
  final DateTime date;
  final int daysRemaining;
  final bool isMajor;

  const UpcomingFeast({
    required this.name,
    required this.date,
    required this.daysRemaining,
    this.isMajor = false,
  });
}

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

  const CopticDayInfo({
    required this.copticYear,
    required this.copticMonth,
    required this.copticDay,
    required this.monthName,
    this.feastName,
    this.feastDescription,
    this.fastStatus = FastingStatus.none,
    this.seasonName,
    this.readings = const [],
    this.upcomingFeasts = const [],
  });
}
```

- [x] **Step 2: Create CopticCalendarService**

```dart
// lib/features/church/data/services/coptic_calendar_service.dart
import '../models/coptic_day_info.dart';

class CopticCalendarService {
  static const List<String> _copticMonths = [
    'Tout', 'Baba', 'Hator', 'Kiahk', 'Toba', 'Amshir',
    'Baramhat', 'Baramouda', 'Bashans', 'Paona', 'Epep', 'Mesra', 'Nasie',
  ];

  static const List<String> _gregorianMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Compute Coptic date from a Gregorian DateTime.
  static CopticDateResult _toCopticDate(DateTime greg) {
    int year = greg.year;
    int month = greg.month;
    int day = greg.day;

    // Coptic year starts on 11/12 September (September 12 after Coptic leap year)
    int copticYear = year - 283;
    // Months Sept-Dec: copticYear = year - 283; Jan-Aug: copticYear = year - 284
    if (month < 9) {
      copticYear = year - 284;
    }

    // Days since Coptic New Year (1 Tout = 11/12 Sep)
    final copticNewYear = DateTime(year, 9, 11);
    final diff = greg.difference(copticNewYear).inDays;
    
    int copticMonth = 1;
    int copticDay = 1;
    if (diff >= 0) {
      copticDay = diff + 1;
      copticMonth = 1;
      int daysInMonth = 30;
      while (copticDay > daysInMonth) {
        copticDay -= daysInMonth;
        copticMonth++;
        if (copticMonth == 13) {
          // Nasie: 5 or 6 days
          daysInMonth = _isCopticLeapYear(copticYear) ? 6 : 5;
        } else {
          daysInMonth = 30;
        }
      }
    }

    return CopticDateResult(
      year: copticYear,
      month: copticMonth,
      day: copticDay,
      monthName: _copticMonths[copticMonth - 1],
    );
  }

  static bool _isCopticLeapYear(int copticYear) {
    // Coptic leap year: year divisible by 4 (but not by 100 unless by 400)
    return (copticYear % 4 == 0) && (copticYear % 100 != 0 || copticYear % 400 == 0);
  }

  static CopticDayInfo computeToday() {
    return computeForDate(DateTime.now());
  }

  static CopticDayInfo computeForDate(DateTime date) {
    final cd = _toCopticDate(date);
    final feast = _getFeastForDate(cd.month, cd.day, cd.year);
    final fastStatus = _getFastingStatus(date, cd.month, cd.day);
    final season = _getSeason(date, cd.month, cd.day);
    final readings = _getReadingsForDate(cd.month, cd.day, cd.year);
    final upcoming = _getUpcomingFeasts(date);

    return CopticDayInfo(
      copticYear: cd.year,
      copticMonth: cd.month,
      copticDay: cd.day,
      monthName: cd.monthName,
      feastName: feast?.name,
      feastDescription: feast?.description,
      fastStatus: fastStatus,
      seasonName: season,
      readings: readings,
      upcomingFeasts: upcoming,
    );
  }

  static _FeastInfo? _getFeastForDate(int month, int day, int year) {
    // Partial feast lookup table — expand as needed
    const feasts = {
      // (month, day): (name, description)
      (7, 1): ('Feast of the Entry of the Lord into Egypt', 'Commemorating the Holy Family\'s flight into Egypt'),
      (7, 21): ('Feast of the Transfiguration', 'The revelation of Christ\'s divine glory on Mount Tabor'),
      (12, 6): ('Feast of the Nativity', 'The birth of our Lord and Savior Jesus Christ'),
    };
    final key = (month, day);
    final f = feasts[key];
    if (f != null) return _FeastInfo(f.$1, f.$2);
    return null;
  }

  static FastingStatus _getFastingStatus(DateTime greg, int copticMonth, int copticDay) {
    // Wednesdays and Fridays are fasting days (exception: 50 days after Easter)
    final weekday = greg.weekday;
    if (weekday == DateTime.wednesday || weekday == DateTime.friday) {
      return FastingStatus.fishAllowed;
    }
    return FastingStatus.none;
  }

  static String? _getSeason(DateTime greg, int copticMonth, int copticDay) {
    // Rough seasons — refine with actual Coptic calendar
    if (copticMonth == 4) return 'Kiahk Month (Advent Preparation)';
    if (copticMonth == 12) return 'Nativity Season';
    return null;
  }

  static List<ScriptureReference> _getReadingsForDate(int month, int day, int year) {
    // Return default readings — YouVersion will fetch actual text
    return [
      const ScriptureReference(
        book: 'John',
        chapter: '1',
        verses: '1-17',
        displayName: 'John 1:1-17',
      ),
    ];
  }

  static List<UpcomingFeast> _getUpcomingFeasts(DateTime now) {
    const feasts = {
      'Nativity': (12, 29),
      'Epiphany': (1, 19),
      'Entry of Lord into Egypt': (6, 1),
      'Transfiguration': (8, 19),
    };
    final result = <UpcomingFeast>[];
    for (final entry in feasts.entries) {
      final feastDate = DateTime(now.year, entry.value.$1, entry.value.$2);
      final adjusted = feastDate.isBefore(now)
          ? DateTime(now.year + 1, entry.value.$1, entry.value.$2)
          : feastDate;
      final days = adjusted.difference(now).inDays;
      if (days > 0 && days <= 365) {
        result.add(UpcomingFeast(
          name: entry.key,
          date: adjusted,
          daysRemaining: days,
          isMajor: ['Nativity', 'Epiphany'].contains(entry.key),
        ));
      }
    }
    result.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return result.take(5).toList();
  }
}

class CopticDateResult {
  final int year;
  final int month;
  final int day;
  final String monthName;
  const CopticDateResult({required this.year, required this.month, required this.day, required this.monthName});
}

class _FeastInfo {
  final String name;
  final String description;
  const _FeastInfo(this.name, this.description);
}
```

---

### Task 3: Create YouVersionService

**Files:**
- Create: `lib/features/church/data/services/youversion_service.dart`

- [x] **Step 1: Create YouVersionService**

```dart
// lib/features/church/data/services/youversion_service.dart
import 'package:dio/dio.dart';
import '../models/coptic_day_info.dart';

class YouVersionService {
  final Dio _dio;
  final String? _apiKey;

  YouVersionService({required Dio dio, String? apiKey})
      : _dio = dio,
        _apiKey = apiKey;

  static const _baseUrl = 'https://api.youversion.com';

  /// Get the URL to open a passage in the YouVersion Bible app.
  String getPassageUrl(ScriptureReference ref) {
    final encoded = Uri.encodeComponent(ref.displayName);
    return 'https://www.bible.com/bible/1/$encoded';
  }

  /// Fetch passage text from YouVersion API.
  /// Returns null if API key is not configured or request fails.
  Future<String?> getPassageText(ScriptureReference ref) async {
    if (_apiKey == null || _apiKey!.isEmpty) return null;
    try {
      final response = await _dio.get(
        '$_baseUrl/bible/passage',
        queryParameters: {
          'q': ref.displayName,
          'version': '1', // NIV
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_apiKey'},
        ),
      );
      return response.data['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
```

---

### Task 4: Update ChurchBloc

**Files:**
- Modify: `lib/features/church/presentation/bloc/church_bloc.dart`

- [x] **Step 1: Rewrite ChurchBloc with streak and stats**

```dart
// lib/features/church/presentation/bloc/church_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/church_repository.dart';
import '../../data/models/mass_attendance.dart';
import '../../data/models/ministry_task.dart';

// Events
abstract class ChurchEvent extends Equatable {
  const ChurchEvent();
  @override
  List<Object?> get props => [];
}

class LoadChurchData extends ChurchEvent {}

class MarkAttendanceEvent extends ChurchEvent {
  final DateTime date;
  final ServiceType type;
  const MarkAttendanceEvent(this.date, this.type);
  @override
  List<Object?> get props => [date, type];
}

class DeleteAttendanceEvent extends ChurchEvent {
  final DateTime date;
  final ServiceType type;
  const DeleteAttendanceEvent(this.date, this.type);
  @override
  List<Object?> get props => [date, type];
}

class UpdateServiceTaskEvent extends ChurchEvent {
  final MinistryTask task;
  const UpdateServiceTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class AddTaskEvent extends ChurchEvent {
  final MinistryTask task;
  const AddTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

enum ChurchStatus { initial, loading, success, failure }

// States
class ChurchState extends Equatable {
  final ChurchStatus status;
  final List<MassAttendance> attendances;
  final List<MinistryTask> tasks;
  final int currentStreak;
  final int bestStreak;
  final String? errorMessage;

  const ChurchState({
    this.status = ChurchStatus.initial,
    this.attendances = const [],
    this.tasks = const [],
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.errorMessage,
  });

  ChurchState copyWith({
    ChurchStatus? status,
    List<MassAttendance>? attendances,
    List<MinistryTask>? tasks,
    int? currentStreak,
    int? bestStreak,
    bool clearError = false,
    String? errorMessage,
  }) {
    return ChurchState(
      status: status ?? this.status,
      attendances: attendances ?? this.attendances,
      tasks: tasks ?? this.tasks,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, attendances, tasks, currentStreak, bestStreak, errorMessage];
}

// Bloc
class ChurchBloc extends Bloc<ChurchEvent, ChurchState> {
  final ChurchRepository _repository;

  ChurchBloc(this._repository) : super(const ChurchState()) {
    on<LoadChurchData>((event, emit) async {
      emit(state.copyWith(status: ChurchStatus.loading));
      try {
        final attendances = await _repository.getAttendances();
        final tasks = await _repository.getTasks();
        final currentStreak = await _repository.getStreak();
        final bestStreak = await _repository.getBestStreak();
        emit(state.copyWith(
          status: ChurchStatus.success,
          attendances: attendances,
          tasks: tasks,
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          clearError: true,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to load church data.',
        ));
      }
    });

    on<MarkAttendanceEvent>((event, emit) async {
      final newAttendance = MassAttendance()
        ..date = DateTime(event.date.year, event.date.month, event.date.day)
        ..services = [event.type];

      final updatedAttendances = List<MassAttendance>.from(state.attendances)..add(newAttendance);
      emit(state.copyWith(
        attendances: updatedAttendances,
        status: ChurchStatus.success,
        clearError: true,
      ));

      try {
        await _repository.markAttendance(event.date, event.type);
        final currentStreak = await _repository.getStreak();
        final bestStreak = await _repository.getBestStreak();
        emit(state.copyWith(currentStreak: currentStreak, bestStreak: bestStreak));
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to save attendance.',
        ));
        add(LoadChurchData());
      }
    });

    on<DeleteAttendanceEvent>((event, emit) async {
      final updatedAttendances = state.attendances.map((a) {
        if (a.date == DateTime(event.date.year, event.date.month, event.date.day)) {
          final newServices = a.services.where((s) => s != event.type).toList();
          if (newServices.isEmpty) return null;
          final copy = MassAttendance()
            ..id = a.id
            ..date = a.date
            ..services = newServices;
          return copy;
        }
        return a;
      }).whereType<MassAttendance>().toList();

      emit(state.copyWith(attendances: updatedAttendances));
      try {
        await _repository.deleteAttendance(event.date, event.type);
        final streak = await _repository.getStreak();
        emit(state.copyWith(currentStreak: streak));
      } catch (e) {
        add(LoadChurchData());
      }
    });

    on<UpdateServiceTaskEvent>((event, emit) async {
      final updatedTasks = state.tasks.map((t) => t.id == event.task.id ? event.task : t).toList();
      emit(state.copyWith(tasks: updatedTasks, status: ChurchStatus.success, clearError: true));
      try {
        await _repository.saveTask(event.task);
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to update task.',
        ));
        add(LoadChurchData());
      }
    });

    on<AddTaskEvent>((event, emit) async {
      final updatedTasks = List<MinistryTask>.from(state.tasks)..add(event.task);
      emit(state.copyWith(tasks: updatedTasks, status: ChurchStatus.success, clearError: true));
      try {
        await _repository.saveTask(event.task);
      } catch (e) {
        emit(state.copyWith(
          status: ChurchStatus.failure,
          errorMessage: 'Failed to add task.',
        ));
        add(LoadChurchData());
      }
    });
  }
}
```

---

### Task 5: Create CopticBloc

**Files:**
- Create: `lib/features/church/presentation/bloc/coptic_bloc.dart`

- [x] **Step 1: Create CopticBloc**

```dart
// lib/features/church/presentation/bloc/coptic_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/coptic_calendar_service.dart';
import '../../data/services/youversion_service.dart';
import '../../data/models/coptic_day_info.dart';

// Events
class LoadCopticData extends CopticEvent {}

abstract class CopticEvent extends Equatable {
  const CopticEvent();
  @override
  List<Object?> get props => [];
}

// States
abstract class CopticState extends Equatable {
  const CopticState();
  @override
  List<Object?> get props => [];
}

class CopticInitial extends CopticState {}

class CopticLoading extends CopticState {}

class CopticLoaded extends CopticState {
  final CopticDayInfo dayInfo;
  final Map<String, String?> passageTexts; // ref -> text
  const CopticLoaded({required this.dayInfo, this.passageTexts = const {}});
  @override
  List<Object?> get props => [dayInfo, passageTexts];
}

class CopticError extends CopticState {
  final String message;
  const CopticError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class CopticBloc extends Bloc<CopticEvent, CopticState> {
  final YouVersionService? _youVersion;

  CopticBloc({YouVersionService? youVersion})
      : _youVersion = youVersion,
        super(CopticInitial()) {
    on<LoadCopticData>((event, emit) async {
      emit(CopticLoading());
      try {
        final dayInfo = CopticCalendarService.computeToday();
        Map<String, String?> texts = {};
        if (_youVersion != null) {
          for (final ref in dayInfo.readings) {
            final text = await _youVersion!.getPassageText(ref);
            if (text != null) {
              texts[ref.displayName] = text;
            }
          }
        }
        emit(CopticLoaded(dayInfo: dayInfo, passageTexts: texts));
      } catch (e) {
        emit(CopticError('Failed to load Coptic data.'));
      }
    });
  }
}
```

---

### Task 6: Create InlineErrorWidget (if doesn't exist)

**Files:**
- Check if exists: `lib/shared/widgets/inline_error_widget.dart`
- If not, create it.

- [x] **Step 1: Check if InlineErrorWidget exists**

Run: `dir "lib\shared\widgets\inline_error_widget.dart"`

- [x] **Step 2: Create if missing**

```dart
// lib/shared/widgets/inline_error_widget.dart
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.accentRose, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

### Task 7: Create Shimmer Skeleton Widget

**Files:**
- Check if exists: `lib/shared/widgets/shimmer/` directory
- Create: `lib/features/church/presentation/widgets/church_skeleton.dart`

- [x] **Step 1: Create ChurchSkeleton**

```dart
// lib/features/church/presentation/widgets/church_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/app_theme.dart';

class ChurchSkeleton extends StatelessWidget {
  const ChurchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgSurface,
      highlightColor: AppTheme.bgElevated,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBlock(height: 160),
            const SizedBox(height: 16),
            _buildBlock(height: 80),
            const SizedBox(height: 16),
            _buildBlock(height: 200),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
```

---

### Task 8: Redesign ChurchScreen Shell

**Files:**
- Modify: `lib/features/church/presentation/screens/church_screen.dart`
- Create: `lib/features/church/presentation/screens/coptic_tab.dart`
- Modify: `lib/features/church/presentation/screens/attendance_screen.dart`
- Modify: `lib/features/church/presentation/screens/ministry_kanban_screen.dart`
- Modify: `lib/features/church/presentation/screens/confession_auth_screen.dart`

- [x] **Step 1: Rewrite ChurchScreen shell**

```dart
// lib/features/church/presentation/screens/church_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/coptic_bloc.dart';
import '../bloc/confession_bloc.dart';
import 'coptic_tab.dart';
import 'attendance_screen.dart';
import 'ministry_kanban_screen.dart';
import 'confession_auth_screen.dart';

class ChurchScreen extends StatefulWidget {
  const ChurchScreen({super.key});

  @override
  State<ChurchScreen> createState() => _ChurchScreenState();
}

class _ChurchScreenState extends State<ChurchScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<CopticBloc>().add(LoadCopticData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Church'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Coptic'),
            Tab(text: 'Attendance'),
            Tab(text: 'Ministry'),
            Tab(text: 'Confession'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CopticTab(),
          AttendanceScreen(),
          MinistryKanbanScreen(),
          ConfessionAuthScreen(),
        ],
      ),
    );
  }
}
```

- [x] **Step 2: Create CopticTab widget**

```dart
// lib/features/church/presentation/screens/coptic_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';
import '../bloc/coptic_bloc.dart';
import '../widgets/church_skeleton.dart';

class CopticTab extends StatelessWidget {
  const CopticTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CopticBloc, CopticState>(
      builder: (context, state) {
        if (state is CopticLoading || state is CopticInitial) {
          return const ChurchSkeleton();
        }
        if (state is CopticError) {
          return InlineErrorWidget(
            message: state.message,
            onRetry: () => context.read<CopticBloc>().add(LoadCopticData()),
          );
        }
        if (state is CopticLoaded) {
          final info = state.dayInfo;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Zone 1: Header Card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _HeaderCard(info: info),
                ),
              ),
              // Zone 2: Today's Feast
              if (info.feastName != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _FeastCard(info: info),
                  ),
                ),
              // Zone 3: Today's Readings
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _ReadingsCard(info: info, passageTexts: state.passageTexts),
                ),
              ),
              // Zone 4: Upcoming Feasts
              if (info.upcomingFeasts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _UpcomingFeastsCard(feasts: info.upcomingFeasts),
                  ),
                ),
              // Zone 5: Fast Status
              if (info.fastStatus != FastingStatus.none)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _FastStatusCard(info: info),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final CopticDayInfo info;
  const _HeaderCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final fastColor = info.fastStatus == FastingStatus.strict
        ? AppTheme.accentRose
        : info.fastStatus == FastingStatus.fishAllowed
            ? AppTheme.accentMint
            : AppTheme.accentPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentViolet.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.calendar_month, color: AppTheme.accentViolet, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info.copticDay} ${info.monthName} ${info.copticYear} AM',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (info.seasonName != null)
                  Text(
                    info.seasonName!,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fastColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              info.fastStatus == FastingStatus.none ? 'Feast' : 'Fasting',
              style: TextStyle(color: fastColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeastCard extends StatelessWidget {
  final CopticDayInfo info;
  const _FeastCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                info.feastName!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGold,
                ),
              ),
            ],
          ),
          if (info.feastDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              info.feastDescription!,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingsCard extends StatelessWidget {
  final CopticDayInfo info;
  final Map<String, String?> passageTexts;
  const _ReadingsCard({required this.info, required this.passageTexts});

  @override
  Widget build(BuildContext context) {
    if (info.readings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Readings",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...info.readings.map((ref) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                // Open YouVersion URL
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${ref.displayName}...')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppTheme.accentCyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ref.displayName,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textDisabled),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _UpcomingFeastsCard extends StatelessWidget {
  final List<UpcomingFeast> feasts;
  const _UpcomingFeastsCard({required this.feasts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Upcoming Feasts',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: feasts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final feast = feasts[index];
              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feast.isMajor
                      ? AppTheme.accentGold.withValues(alpha: 0.1)
                      : AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: feast.isMajor
                      ? Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feast.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${feast.daysRemaining}d',
                        style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FastStatusCard extends StatelessWidget {
  final CopticDayInfo info;
  const _FastStatusCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final isStrict = info.fastStatus == FastingStatus.strict;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isStrict
            ? AppTheme.accentRose.withValues(alpha: 0.1)
            : AppTheme.accentMint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isStrict ? Icons.block : Icons.check_circle_outline,
            color: isStrict ? AppTheme.accentRose : AppTheme.accentMint,
          ),
          const SizedBox(width: 12),
          Text(
            isStrict ? 'Strict Fast Today' : 'Fast Day — Fish Allowed',
            style: TextStyle(
              color: isStrict ? AppTheme.accentRose : AppTheme.accentMint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 3: Update AttendanceScreen to remove nested Scaffold**

Keep the existing file's content but remove the `Scaffold` wrapper and `AppBar` since `ChurchScreen` already provides those. Also use the new model types and add the mark attendance bottom sheet:

```dart
// attendance_screen.dart changes summary:
// 1. Remove outer Scaffold and AppBar (leave just the body content)
// 2. Replace ChurchStatus enum references with updated enum
// 3. Use ServiceType instead of AttendanceType
// 4. Add mark attendance bottom sheet
// 5. Use ChurchSkeleton for loading
// 6. Use InlineErrorWidget for errors
```

- [x] **Step 4: Update MinistryKanbanScreen to remove nested Scaffold**

Remove outer `Scaffold` and `AppBar`. Use `_buildKanbanColumn` with priority badges. Update task creation to use `MinistryTask` with `priority` field.

- [x] **Step 5: Update ConfessionAuthScreen to remove nested Scaffold**

Remove outer `Scaffold`. Keep auth logic intact. Update route back to use proper navigation.

---

### Task 9: Update Home Screen Church Card

**Files:**
- Modify: `lib/features/home/presentation/screens/home_screen.dart`

- [x] **Step 1: Update _buildChurchCard with real data**

```dart
Widget _buildChurchCard(BuildContext context) {
  return BlocBuilder<ChurchBloc, ChurchState>(
    builder: (context, state) {
      int streak = state.currentStreak;
      final today = DateTime.now();
      final todayMarked = state.attendances.any(
        (a) =>
            a.date.year == today.year &&
            a.date.month == today.month &&
            a.date.day == today.day,
      );
      return _buildSnapshotCard(
        context: context,
        domainLabel: todayMarked ? 'MASS TODAY' : 'MASS STREAK',
        heroMetric: '${streak}d streak',
        accentColor: AppTheme.accentViolet,
        route: '/church',
        heroTag: 'hero-church',
      );
    },
  );
}
```

---

### Task 10: Update DI Registration

**Files:**
- Modify: `lib/core/di/injection.dart`

- [x] **Step 1: Register new services**

```dart
// Add after church DI section:
getIt.registerLazySingleton<CopticBloc>(
  () => CopticBloc(
    youVersion: getIt<YouVersionService>(),
  ),
);
getIt.registerLazySingleton<YouVersionService>(
  () => YouVersionService(
    dio: getIt<Dio>(),
    apiKey: dotenv.env['YOUVERSION_API_KEY'],
  ),
);
```

---

### Task 11: Wire Voice Commands

**Files:**
- Modify: `lib/features/voice/domain/command_parser.dart`

- [x] **Step 1: Add church voice commands**

```dart
// In CommandParser.parse(String text):
if (text.contains('mark') && (text.contains('mass') || text.contains('liturgy'))) {
  return CommandIntent(domain: 'church', action: 'markAttendance', parameters: {});
}
if (text.contains('streak') || text.contains('church streak')) {
  return CommandIntent(domain: 'church', action: 'readStreak', parameters: {});
}
```

---

### Task 12: Wire Notification Service

**Files:**
- Modify: `lib/features/church/data/services/church_notification_service.dart`

- [x] **Step 1: Enable notification scheduling**

```dart
// church_notification_service.dart — add scheduleSundayReminder()
// and scheduleFastingReminder() methods.
// Already exists, ensure it's called from main.dart initialization.
```

---

### Task 13: Run Build & Analysis

- [x] **Step 1: Regenerate Isar .g files**

Run: `flutter packages pub run build_runner build --delete-conflicting-outputs`

- [x] **Step 2: Run static analysis**

Run: `flutter analyze`

- [x] **Step 3: Fix any analysis issues**

- [ ] **Step 4: Run debug build**

Run: `flutter build apk --debug`

- [ ] **Step 5: Fix any build issues**