# Phase 1: Isar Schema Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the Isar database schema, multi-device sync outbox, and ingredient seeder script.

**Architecture:** A singleton `IsarService` initializes the unencrypted local database. Every domain write creates a `SyncOutboxRecord`. A background Dart isolate (`SyncWorker`) polls the outbox and syncs to Docker. Every data model includes `deviceId` and `platform` to enable strong Windows/Android telemetry integration.

**Tech Stack:** Isar v3 (`isar`, `isar_flutter_libs`, `isar_generator`), Python 3 (requests) for data generation, Dart Isolates.

---

### Task 1: Isar Service and SyncOutbox

**Files:**
- Create: `lib/core/data/sync_outbox_record.dart`
- Create: `lib/core/data/isar_service.dart`
- Create: `lib/core/data/sync_outbox_repository.dart`
- Create: `test/core/data/sync_outbox_repository_test.dart`

- [ ] **Step 1: Create `SyncOutboxRecord` Isar Collection**

```dart
// lib/core/data/sync_outbox_record.dart
import 'package:isar/isar.dart';

part 'sync_outbox_record.g.dart';

@collection
class SyncOutboxRecord {
  Id id = Isar.autoIncrement;
  late String entityId;
  late String collectionName;
  late String operation; // 'CREATE', 'UPDATE', 'DELETE'
  late String payloadJson;
  @Index()
  late DateTime createdAt;
  @Index()
  String status = 'PENDING'; // 'PENDING', 'SYNCED', 'FAILED'
  String? error;
}
```

- [ ] **Step 2: Create `IsarService` and `SyncOutboxRepository`**

```dart
// lib/core/data/isar_service.dart
import 'package:isar/isar.dart';
import 'sync_outbox_record.dart';

class IsarService {
  static late Isar _instance;
  static Isar get instance => _instance;

  static Future<void> init(String directory) async {
    _instance = await Isar.open(
      [SyncOutboxRecordSchema],
      directory: directory,
    );
  }
}
```

```dart
// lib/core/data/sync_outbox_repository.dart
import 'package:isar/isar.dart';
import 'isar_service.dart';
import 'sync_outbox_record.dart';

class SyncOutboxRepository {
  Future<void> addToOutbox(SyncOutboxRecord record) async {
    await IsarService.instance.writeTxn(() async {
      await IsarService.instance.syncOutboxRecords.put(record);
    });
  }

  Future<List<SyncOutboxRecord>> getPendingBatch({int limit = 50}) async {
    return IsarService.instance.syncOutboxRecords
        .filter()
        .statusEqualTo('PENDING')
        .sortByCreatedAt()
        .limit(limit)
        .findAll();
  }
}
```

- [ ] **Step 3: Run Build Runner**

Run: `rtk proxy flutter pub run build_runner build --delete-conflicting-outputs`
Expected: PASS, `sync_outbox_record.g.dart` generated.

- [ ] **Step 4: Commit**

```bash
rtk proxy git add lib/core/data/
rtk proxy git commit -m "feat: core isar service and sync outbox"
```

### Task 2: Core Data Models (Telemetry & Productivity)

**Files:**
- Create: `lib/features/telemetry/data/models/telemetry_collections.dart`
- Create: `lib/features/productivity/data/models/productivity_collections.dart`

- [ ] **Step 1: Create Telemetry Models with Device Tracking**

```dart
// lib/features/telemetry/data/models/telemetry_collections.dart
import 'package:isar/isar.dart';

part 'telemetry_collections.g.dart';

@collection
class ScreenEvent {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform; // 'android' or 'windows'
  late String eventType; // 'WAKE', 'SLEEP', 'UNLOCK'
  late DateTime timestamp;
}

@collection
class AppUsageRecord {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String packageName;
  late int foregroundMs;
  late DateTime date;
}
```

- [ ] **Step 2: Create Productivity Models**

```dart
// lib/features/productivity/data/models/productivity_collections.dart
import 'package:isar/isar.dart';

part 'productivity_collections.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String title;
  bool isCompleted = false;
  DateTime? dueDate;
  late DateTime createdAt;
}
```

- [ ] **Step 3: Update `IsarService.init` schema array**

Modify: `lib/core/data/isar_service.dart:10-15`
```dart
    _instance = await Isar.open(
      [
        SyncOutboxRecordSchema,
        ScreenEventSchema,
        AppUsageRecordSchema,
        TaskSchema,
      ],
      directory: directory,
    );
```

- [ ] **Step 4: Run Build Runner**

Run: `rtk proxy flutter pub run build_runner build --delete-conflicting-outputs`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
rtk proxy git add lib/features/ lib/core/data/isar_service.dart
rtk proxy git commit -m "feat: telemetry and productivity schemas"
```

### Task 3: SyncWorker Isolate

**Files:**
- Create: `lib/core/data/sync_worker.dart`

- [ ] **Step 1: Implement `SyncWorker`**

```dart
// lib/core/data/sync_worker.dart
import 'dart:isolate';
import 'package:isar/isar.dart';
import 'sync_outbox_repository.dart';
import 'isar_service.dart';

class SyncWorker {
  static Future<void> triggerSync(String dbDirectory) async {
    await Isolate.run(() async {
      // Open Isar inside the isolate
      await IsarService.init(dbDirectory);
      
      final repo = SyncOutboxRepository();
      final batch = await repo.getPendingBatch();
      
      if (batch.isNotEmpty) {
        // Mocking HTTP Sync for now
        print('Syncing ${batch.length} records to Docker backend...');
        
        await IsarService.instance.writeTxn(() async {
          for (var record in batch) {
            record.status = 'SYNCED';
            await IsarService.instance.syncOutboxRecords.put(record);
          }
        });
      }
      
      // Clean exit
      await IsarService.instance.close();
    });
  }
}
```

- [ ] **Step 2: Commit**

```bash
rtk proxy git add lib/core/data/sync_worker.dart
rtk proxy git commit -m "feat: background sync worker isolate"
```

### Task 4: Ingredient Seeder Script

**Files:**
- Create: `scripts/generate_ingredients.py`

- [ ] **Step 1: Write Python Fetch Script**

```python
# scripts/generate_ingredients.py
import json

def generate_stub():
    # In a full implementation, this hits USDA and Open Food Facts API.
    # For now, we generate a high-quality stub for testing.
    items = [
        {"id": "1", "name": "Ful Medames", "calories": 344, "protein": 26.1, "carbs": 58.3, "fat": 1.5, "isFastingCompliant": True},
        {"id": "2", "name": "Chicken Breast", "calories": 165, "protein": 31.0, "carbs": 0.0, "fat": 3.6, "isFastingCompliant": False},
        {"id": "3", "name": "White Rice", "calories": 130, "protein": 2.7, "carbs": 28.0, "fat": 0.3, "isFastingCompliant": True},
    ]
    with open('assets/ingredients_seed.json', 'w') as f:
        json.dump(items, f, indent=2)
    print("Generated ingredients_seed.json")

if __name__ == '__main__':
    generate_stub()
```

- [ ] **Step 2: Run Python Script**

Run: `rtk proxy python scripts/generate_ingredients.py` (ensure `assets/` exists)
Expected: PASS

- [ ] **Step 3: Update `pubspec.yaml` to include assets**

Modify: `pubspec.yaml:70-73`
```yaml
  assets:
    - assets/ingredients_seed.json
```

- [ ] **Step 4: Commit**

```bash
rtk proxy git add scripts/ assets/ pubspec.yaml
rtk proxy git commit -m "build: ingredient seeder generation script"
```
