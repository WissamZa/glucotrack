// Secure storage service for the database encryption key.
//
// Uses flutter_secure_storage which delegates to:
//   - Android: EncryptedSharedPreferences / Android Keystore
//   - iOS: Keychain
//   - Linux/Windows: libsecret / DPAPI (or fallback)
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeystoreService {
  static const _keyStorageKey = 'db_encryption_key';
  static const _keyStorageKey2 = 'db_encryption_key_v2';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Get or create the 32-byte database encryption key.
  /// Returns the key as a base64-encoded string (what SQLCipher expects
  /// when passed as the `password` parameter).
  Future<String> getDbKey() async {
    var key = await _storage.read(key: _keyStorageKey2);
    if (key == null) {
      // Generate 32 cryptographically random bytes
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(key: _keyStorageKey2, value: key);
    }
    return key;
  }

  /// Delete the stored key (used on full data wipe / account reset).
  Future<void> deleteDbKey() async {
    await _storage.delete(key: _keyStorageKey2);
    await _storage.delete(key: _keyStorageKey);
  }
}
