// Tests for backup encryption — round-trip, wrong passphrase rejection,
// tamper detection, and payload-shape helpers used by WebDAV sync.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/services/webdav_sync_service.dart';
import 'package:glucotrack/utils/backup_crypto.dart';

void main() {
  group('BackupCrypto', () {
    const json =
        '{"version":"1.5.0","readings":[{"id":"r1","value":120,"notes":"مرتفع بعد الغداء"}]}';

    test('encrypt → decrypt round-trips Arabic content losslessly', () {
      final encrypted = BackupCrypto.encrypt(json, 'pass-1234');
      expect(BackupCrypto.isEncryptedPayload(encrypted), isTrue);
      final decrypted = BackupCrypto.decrypt(encrypted, 'pass-1234');
      expect(decrypted, json);
      expect(jsonDecode(decrypted), isA<Map<String, dynamic>>());
    });

    test('ciphertext is not readable plaintext', () {
      final encrypted = BackupCrypto.encrypt(json, 'pass-1234');
      final asText = utf8.decode(encrypted, allowMalformed: true);
      expect(
        asText.contains('مرتفع'),
        isFalse,
        reason: 'plaintext must never be visible in the payload',
      );
      expect(asText.contains('120'), isFalse);
    });

    test('same input produces different ciphertext (random salt+nonce)', () {
      final a = BackupCrypto.encrypt(json, 'pw');
      final b = BackupCrypto.encrypt(json, 'pw');
      expect(a, isNot(equals(b)));
    });

    test('wrong passphrase is rejected (GCM tag check)', () {
      final encrypted = BackupCrypto.encrypt(json, 'correct-pass');
      expect(
        () => BackupCrypto.decrypt(encrypted, 'wrong-pass'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('tampered payload is rejected', () {
      final encrypted = BackupCrypto.encrypt(json, 'pw');
      final copy = Uint8List.fromList(encrypted);
      copy[copy.length - 1] ^= 0xFF; // flip a bit in the tag
      expect(
        () => BackupCrypto.decrypt(copy, 'pw'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('plain JSON is not mistaken for an encrypted payload', () {
      expect(
        BackupCrypto.isEncryptedPayload(Uint8List.fromList(utf8.encode(json))),
        isFalse,
      );
      expect(
        () => BackupCrypto.decrypt(Uint8List.fromList(utf8.encode(json)), 'pw'),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('empty passphrase is allowed (still encrypted)', () {
      final encrypted = BackupCrypto.encrypt(json, '');
      expect(BackupCrypto.decrypt(encrypted, ''), json);
    });
  });

  group('WebDavConfig', () {
    test('isComplete requires url, user and passphrase-when-encrypted', () {
      const noUrl = WebDavConfig(url: '', username: 'u', password: 'p');
      expect(noUrl.isComplete, isFalse);

      const missingPass = WebDavConfig(
        url: 'https://cloud.example.com/dav/',
        username: 'u',
        password: 'p',
        encrypt: true,
        passphrase: '',
      );
      expect(missingPass.isComplete, isFalse);

      const complete = WebDavConfig(
        url: 'https://cloud.example.com/dav/glucotrack',
        username: 'u',
        password: 'p',
        encrypt: true,
        passphrase: 'secret',
      );
      expect(complete.isComplete, isTrue);

      const plainNoPass = WebDavConfig(
        url: 'https://cloud.example.com/dav/',
        username: 'u',
        password: 'p',
        encrypt: false,
      );
      expect(plainNoPass.isComplete, isTrue);
    });

    test('baseUrl strips trailing slashes', () {
      const c = WebDavConfig(
        url: 'https://x.example/dav///',
        username: 'u',
        password: 'p',
      );
      expect(c.baseUrl, 'https://x.example/dav');
      expect(c.encryptedFileName, 'glucotrack_backup.bin');
    });

    test('config map round-trip (as stored in secure storage)', () {
      const original = WebDavConfig(
        url: 'https://cloud.example.com/dav/',
        username: 'user@x',
        password: 'pw',
        encrypt: true,
        passphrase: 'secret',
      );
      final restored = WebDavConfig.fromMap(original.toMap());
      expect(restored.url, original.url);
      expect(restored.username, original.username);
      expect(restored.password, original.password);
      expect(restored.encrypt, isTrue);
      expect(restored.passphrase, original.passphrase);
    });

    test('water file names: encrypted mode targets the .bin file', () {
      const c = WebDavConfig(
        url: 'https://x/dav',
        username: 'u',
        password: 'pw',
        encrypt: true,
        passphrase: 'p',
      );
      expect(c.encryptedFileName, 'glucotrack_backup.bin');
      expect(c.plainFileName, 'glucotrack_backup.json');
    });
  });
}
