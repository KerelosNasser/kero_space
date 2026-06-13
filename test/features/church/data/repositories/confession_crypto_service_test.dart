import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/church/data/repositories/confession_crypto_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Simple stub for secure storage
class StubSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    return _data[key];
  }

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

void main() {
  group('ConfessionCryptoService', () {
    late ConfessionCryptoService service;
    late StubSecureStorage stubStorage;

    setUp(() {
      stubStorage = StubSecureStorage();
      service = ConfessionCryptoService(secureStorage: stubStorage);
    });

    test('should derive key and save salt on first run', () async {
      final key = await service.deriveKey('my_passphrase');
      expect(key, isNotNull);
      
      final savedSalt = await stubStorage.read(key: 'confession_salt');
      expect(savedSalt, isNotNull);
      expect(base64Decode(savedSalt!).length, equals(16));
    });

    test('should use existing salt on subsequent runs', () async {
      final key1 = await service.deriveKey('my_passphrase');
      final salt1 = await stubStorage.read(key: 'confession_salt');
      
      final key2 = await service.deriveKey('my_passphrase');
      final salt2 = await stubStorage.read(key: 'confession_salt');
      
      expect(salt1, equals(salt2));
      
      final keyBytes1 = await key1.extractBytes();
      final keyBytes2 = await key2.extractBytes();
      expect(keyBytes1, equals(keyBytes2));
    });

    test('encrypt and decrypt should work symmetrically', () async {
      final key = await service.deriveKey('secret_pass');
      const plaintext = "This is my confession test";
      
      final ciphertext = await service.encrypt(plaintext, key);
      expect(ciphertext, isNot(equals(utf8.encode(plaintext))));
      
      final decrypted = await service.decrypt(ciphertext, key);
      expect(decrypted, equals(plaintext));
    });
  });
}
