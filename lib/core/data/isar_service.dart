import 'package:isar/isar.dart';
import 'sync_outbox_record.dart';
import '../../features/telemetry/data/models/telemetry_collections.dart';
import '../../features/productivity/data/models/productivity_collections.dart';
import '../../features/health/data/models/health_collections.dart';
import '../../features/finance/data/models/finance_collections.dart';
import '../../features/church/data/models/church_collections.dart';

class IsarService {
  static late Isar _instance;
  static Isar get instance => _instance;

  static Future<void> init(String directory) async {
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
        InvoiceSchema,
        TransactionSchema,
        EGXHoldingSchema,
        EGXPriceSnapshotSchema,
        MassAttendanceSchema,
        ConfessionEntrySchema,
        MinistryTaskSchema,
      ],
      directory: directory,
    );
  }
}
