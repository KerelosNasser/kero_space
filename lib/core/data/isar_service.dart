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
