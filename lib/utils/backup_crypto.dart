// Client-side encryption for cloud-sync backups.
//
// AES-256-GCM with a key derived from the user's passphrase (PBKDF2-HMAC-
// SHA256, 100k iterations, random 16-byte salt, random 12-byte nonce).
// The cloud/server only ever stores ciphertext — anyone without the
// passphrase (including the storage provider) learns nothing.
//
// File format: ASCII magic "GCTE1" + salt(16) + nonce(12) + ciphertext(+16B
// GCM tag). The magic lets restore detect encrypted payloads automatically.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class BackupCrypto {
  BackupCrypto._();

  static const String _magic = 'GCTE1';
  static const int _saltLen = 16;
  static const int _nonceLen = 12;
  static const int _iterations = 100000;
  static const int _keyLen = 32;

  /// True when [data] carries the encrypted-backup magic header.
  static bool isEncryptedPayload(Uint8List data) {
    final magic = ascii.encode(_magic);
    if (data.length <= magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (data[i] != magic[i]) return false;
    }
    return true;
  }

  static Uint8List encrypt(String plaintext, String passphrase) {
    final rnd = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLen, (_) => rnd.nextInt(256)),
    );
    final nonce = Uint8List.fromList(
      List<int>.generate(_nonceLen, (_) => rnd.nextInt(256)),
    );
    final key = _deriveKey(passphrase, salt);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
    final cipherText = cipher.process(
      Uint8List.fromList(utf8.encode(plaintext)),
    );

    final builder = BytesBuilder()
      ..add(ascii.encode(_magic))
      ..add(salt)
      ..add(nonce)
      ..add(cipherText);
    return builder.toBytes();
  }

  /// Decrypts a payload produced by [encrypt].
  ///
  /// Throws [BackupCryptoException] when the passphrase is wrong or the data
  /// is corrupt (the GCM tag check fails).
  static String decrypt(Uint8List data, String passphrase) {
    final magic = ascii.encode(_magic);
    final magicMatches = () {
      if (data.length <= magic.length) return false;
      for (var i = 0; i < magic.length; i++) {
        if (data[i] != magic[i]) return false;
      }
      return true;
    }();
    if (data.length <= magic.length + _saltLen + _nonceLen + 16 ||
        !magicMatches) {
      throw const BackupCryptoException('not_an_encrypted_backup');
    }

    final salt = Uint8List.sublistView(
      data,
      magic.length,
      magic.length + _saltLen,
    );
    final nonce = Uint8List.sublistView(
      data,
      magic.length + _saltLen,
      magic.length + _saltLen + _nonceLen,
    );
    final cipherText = Uint8List.sublistView(
      data,
      magic.length + _saltLen + _nonceLen,
    );

    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(_deriveKey(passphrase, salt)),
            128,
            nonce,
            Uint8List(0),
          ),
        );
      final plain = cipher.process(cipherText);
      return utf8.decode(plain);
    } on InvalidCipherTextException {
      throw const BackupCryptoException('wrong_passphrase_or_corrupt');
    }
  }

  static Uint8List _deriveKey(String passphrase, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, _keyLen));
    return derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
  }
}

/// Domain error for backup encryption/decryption failures.
class BackupCryptoException implements Exception {
  final String code;
  const BackupCryptoException(this.code);

  @override
  String toString() => 'BackupCryptoException($code)';
}
