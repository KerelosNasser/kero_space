import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConfessionCryptoService {
  final FlutterSecureStorage _secureStorage;
  static const _saltKey = 'confession_salt';

  ConfessionCryptoService({FlutterSecureStorage? secureStorage}) 
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Derives the encryption key using Argon2id.
  Future<SecretKey> deriveKey(String passphrase) async {
    final argon2 = Argon2id(
      memory: 65536,
      iterations: 3,
      parallelism: 4,
      hashLength: 32,
    );

    List<int> salt;
    final storedSalt = await _secureStorage.read(key: _saltKey);
    
    if (storedSalt != null) {
      salt = base64Decode(storedSalt);
    } else {
      salt = SecretKeyData.random(length: 16).bytes;
      await _secureStorage.write(key: _saltKey, value: base64Encode(salt));
    }

    final derivedKey = await argon2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );

    return derivedKey;
  }

  /// Encrypts plaintext using AES-256-GCM.
  Future<List<int>> encrypt(String plaintext, SecretKey key) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
    );
    // secretBox contains cipherText, nonce, and mac
    return secretBox.concatenation();
  }

  /// Decrypts ciphertext using AES-256-GCM.
  Future<String> decrypt(List<int> ciphertext, SecretKey key) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox.fromConcatenation(
      ciphertext,
      nonceLength: algorithm.nonceLength,
      macLength: algorithm.macAlgorithm.macLength,
    );

    final clearTextBytes = await algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return utf8.decode(clearTextBytes);
  }
}
