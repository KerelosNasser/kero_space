import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class ConfessionCryptoService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  static const _saltKey = 'confession_salt';
  static const _biometricPassphraseKey = 'confession_biometric_passphrase';

  ConfessionCryptoService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

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

  /// Checks if the device supports biometrics and has registered biometrics.
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Checks if biometrics has been enabled by checking if the passphrase exists.
  Future<bool> isBiometricsEnabled() async {
    final stored = await _secureStorage.read(key: _biometricPassphraseKey);
    return stored != null;
  }

  /// Securely stores the passphrase for biometric login.
  Future<void> savePassphrase(String passphrase) async {
    await _secureStorage.write(
      key: _biometricPassphraseKey,
      value: passphrase,
    );
  }

  /// Authenticates using biometrics and returns the stored passphrase.
  Future<String?> retrievePassphraseWithBiometrics() async {
    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock your confessions log',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        return await _secureStorage.read(key: _biometricPassphraseKey);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Disables biometric login by deleting the stored passphrase.
  Future<void> disableBiometrics() async {
    await _secureStorage.delete(key: _biometricPassphraseKey);
  }
}
