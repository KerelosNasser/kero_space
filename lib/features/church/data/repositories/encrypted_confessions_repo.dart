import 'package:isar/isar.dart';
import 'package:cryptography/cryptography.dart';
import 'confession_crypto_service.dart';
import '../models/confession_entry.dart';

class EncryptedIsarConfessionsRepo {
  final Isar _isar;
  final ConfessionCryptoService _cryptoService;

  EncryptedIsarConfessionsRepo(this._isar, this._cryptoService);

  Future<void> saveConfession(String text, SecretKey sessionKey, DateTime date) async {
    final encryptedPayload = await _cryptoService.encrypt(text, sessionKey);
    
    final entry = ConfessionEntry()
      ..date = date
      ..encryptedPayload = encryptedPayload;

    await _isar.writeTxn(() async {
      await _isar.confessions.put(entry);
    });
  }

  Future<List<Map<String, dynamic>>> getConfessions(SecretKey sessionKey) async {
    final entries = await _isar.confessions.where().sortByDateDesc().findAll();
    
    final result = <Map<String, dynamic>>[];
    for (var entry in entries) {
      try {
        final decryptedText = await _cryptoService.decrypt(entry.encryptedPayload, sessionKey);
        result.add({
          'id': entry.id,
          'date': entry.date,
          'text': decryptedText,
        });
      } catch (e) {
        // If decryption fails, skip.
      }
    }
    return result;
  }
}
