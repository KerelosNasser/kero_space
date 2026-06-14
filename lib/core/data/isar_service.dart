import 'package:isar/isar.dart';
import 'sync_outbox_record.dart';
import '../../features/telemetry/data/models/telemetry_collections.dart';
import '../../features/productivity/data/models/productivity_collections.dart';
import '../../features/health/data/models/health_collections.dart';
import '../../features/finance/data/models/finance_collections.dart';
import '../../features/church/data/models/mass_attendance.dart';
import '../../features/church/data/models/confession_entry.dart';
import '../../features/church/data/models/ministry_task.dart';
import '../../features/church/data/models/ministry_member.dart';

class IsarService {
  static late Isar _instance;
  static bool _initialized = false;

  static Isar get instance {
    assert(_initialized, 'IsarService.init() must be called before accessing instance.');
    return _instance;
  }

  static bool get isInitialized => _initialized;

  static Future<void> init(String directory) async {
    if (_initialized) return; // Idempotent — safe to call from multiple isolates.
    _instance = await Isar.open(
      [
        SyncOutboxRecordSchema,
        ScreenEventSchema,
        AppUsageRecordSchema,
        TelemetryEventSchema,
        TaskSchema,
        NoteSchema,
        CalendarEventSchema,
        HealthRecordSchema,
        MealEntrySchema,
        IngredientSchema,
        UserProfileSchema,
        TransactionSchema,
        BudgetSchema,
        EGXHoldingSchema,
        EGXPriceSnapshotSchema,
        EGXWatchlistSchema,
        CareerTaskSchema,
        MassAttendanceSchema,
        ConfessionEntrySchema,
        MinistryTaskSchema,
        MinistryMemberSchema,
      ],
      directory: directory,
      name: 'kero_space',
    );
    _initialized = true;
  }
}
