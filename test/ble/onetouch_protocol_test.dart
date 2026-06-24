// Unit tests for the OneTouch BLE protocol module.
//
// These tests can run without a physical meter — they verify the pure-Dart
// protocol logic (CRC, framing, AES auth, record parsing) against known
// vectors derived from the xDrip and xavaro open-source implementations.
//
// Run with: `flutter test test/ble/onetouch_protocol_test.dart`
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/ble/onetouch_protocol.dart';

void main() {
  group('crc16ccitt', () {
    test('standard test vector "123456789" -> 0x29B1 (CCITT-FALSE)', () {
      // Reference: https://reveng.sourceforge.io/crc-catalogue/16.htm#crc.cat.crc-16-ccitt-false
      const input = '123456789';
      final bytes = input.codeUnits;
      final crc = crc16ccitt(bytes);
      expect(crc, 0x29B1, reason: 'CRC-16/CCITT-FALSE of "123456789" must be 0x29B1');
    });

    test('empty input -> 0xFFFF (init value)', () {
      expect(crc16ccitt([]), 0xFFFF);
    });

    test('single byte 0x00 -> 0xE1F0', () {
      // Computed by hand: CRC-16/CCITT-FALSE of {0x00}
      // Initial 0xFFFF, 8 bit-iterations of (crc<<1) ^ 0x1021 when top bit set
      expect(crc16ccitt([0x00]), 0xE1F0);
    });
  });

  group('OneTouchFraming', () {
    test('frame + unframe round-trip preserves message', () {
      final message = <int>[0x20, 0x02]; // ReadRtc command
      final framed = OneTouchFraming.frame(message);
      // Frame layout: STX(1) + length(1) + linkCtrl(1) + cmdPrefix(1) + msg(2) + ETX(1) + CRC(2) = 9 bytes
      expect(framed.length, 9);
      expect(framed[0], OneTouchFraming.stx);
      expect(framed[1], 9); // total length
      expect(framed[2], OneTouchFraming.linkControl);
      expect(framed[3], OneTouchFraming.commandPrefix);
      expect(framed[4], 0x20);
      expect(framed[5], 0x02);
      expect(framed[6], OneTouchFraming.etx);

      final unframed = OneTouchFraming.unframe(framed);
      expect(unframed, isNotNull);
      expect(unframed, equals(message));
    });

    test('unframe rejects truncated packets', () {
      expect(OneTouchFraming.unframe([0x02, 0x09]), isNull);
    });

    test('unframe rejects wrong STX', () {
      expect(OneTouchFraming.unframe([0xFF, 0x09, 0x00, 0x03, 0x20, 0x02, 0x03, 0xFF, 0xFF]), isNull);
    });

    test('unframe rejects corrupted CRC', () {
      final framed = OneTouchFraming.frame([0x20, 0x02]);
      // Flip a bit in the CRC
      framed[framed.length - 1] ^= 0xFF;
      expect(OneTouchFraming.unframe(framed), isNull);
    });
  });

  group('OneTouchTransport', () {
    test('buildTx prepends 0x01 header (single packet)', () {
      final tx = OneTouchTransport.buildTx([0x20, 0x02]);
      expect(tx[0], 0x01); // header = "1 packet total"
      expect(tx[1], OneTouchFraming.stx);
    });

    test('parseRx inverts buildTx (single-packet round-trip)', () {
      final message = <int>[0x06, 0x00, 0x00, 0x00, 0x00]; // status=OK + 4-byte payload
      final tx = OneTouchTransport.buildTx(message);
      final parsed = OneTouchTransport.parseRx(tx);
      expect(parsed, isNotNull);
      expect(parsed, equals(message));
    });

    test('parseRx returns null for ACK byte (0x81)', () {
      expect(OneTouchTransport.parseRx([0x81]), isNull);
    });

    test('parseRx returns null for empty input', () {
      expect(OneTouchTransport.parseRx([]), isNull);
    });

    test('buildAck returns 0x81 (xDrip-compatible)', () {
      final ack = OneTouchTransport.buildAck();
      expect(ack, [0x81]);
    });
  });

  group('OneTouchAuth', () {
    test('AES key is exactly 16 bytes', () {
      expect(OneTouchAuth.key.length, 16);
    });

    test('AES key matches the xavaro-deobfuscated value', () {
      // From xavaro Simple.dezify("==:@M6J0JGMD?6=7839291L4M0?F011A")
      // Hex: 483bd3c2cbdf6345160004e6d56d948c
      final expected = [
        0x48, 0x3b, 0xd3, 0xc2, 0xcb, 0xdf, 0x63, 0x45,
        0x16, 0x00, 0x04, 0xe6, 0xd5, 0x6d, 0x94, 0x8c,
      ];
      expect(OneTouchAuth.key, Uint8List.fromList(expected));
    });

    test('parseChallenge decodes UTF-16LE hex string', () {
      // 32-char hex string = 16 bytes when decoded
      const hexStr = 'A1B2C3D4E5F6A7B8C1D2E3F4A5B6C7D8';
      final payload = <int>[0x06]; // status
      for (final c in hexStr.codeUnits) {
        payload.add(c & 0xFF);
        payload.add((c >> 8) & 0xFF);
      }
      final challenge = OneTouchAuth.parseChallenge(payload);
      expect(challenge.length, 16);
      expect(challenge, equals([
        0xA1, 0xB2, 0xC3, 0xD4, 0xE5, 0xF6, 0xA7, 0xB8,
        0xC1, 0xD2, 0xE3, 0xF4, 0xA5, 0xB6, 0xC7, 0xD8,
      ]));
    });

    test('parseChallenge rejects too-short input', () {
      // Only 16 hex chars = 8 bytes — not enough for a 16-byte challenge
      const hexStr = 'A1B2C3D4E5F6A7B8';
      final payload = <int>[0x06];
      for (final c in hexStr.codeUnits) {
        payload.add(c & 0xFF);
        payload.add((c >> 8) & 0xFF);
      }
      final challenge = OneTouchAuth.parseChallenge(payload);
      expect(challenge.length, 0);
    });

    test('computeToken produces 16-byte output', () {
      final challenge = Uint8List.fromList(List.filled(16, 0x42));
      final token = OneTouchAuth.computeToken(challenge);
      expect(token.length, 16);
    });

    test('computeToken is deterministic (same input -> same output)', () {
      final challenge = Uint8List.fromList([
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
      ]);
      final t1 = OneTouchAuth.computeToken(challenge);
      final t2 = OneTouchAuth.computeToken(challenge);
      expect(t1, equals(t2));
    });

    test('computeToken rejects non-16-byte challenge', () {
      expect(
        () => OneTouchAuth.computeToken(Uint8List(15)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('OneTouchProtocol - command builders', () {
    test('buildQueryChallenge', () {
      expect(OneTouchProtocol.buildQueryChallenge(), [0xE6, 0x02, 0x08]);
    });

    test('buildEnableFeatures', () {
      final token = Uint8List.fromList(List.filled(16, 0xAB));
      final cmd = OneTouchProtocol.buildEnableFeatures(token);
      expect(cmd[0], 0x11);
      expect(cmd.length, 17);
      expect(cmd.sublist(1), equals(token));
    });

    test('buildReadRtc', () {
      expect(OneTouchProtocol.buildReadRtc(), [0x20, 0x02]);
    });

    test('buildReadCounter', () {
      expect(
        OneTouchProtocol.buildReadCounter(OneTouchCounterSelector.testCount),
        [0x0A, 0x02, 0x06],
      );
    });

    test('buildReadRecordCount', () {
      expect(OneTouchProtocol.buildReadRecordCount(), [0x27, 0x00]);
    });

    test('buildReadRecord encodes 16-bit LE sequence number', () {
      expect(OneTouchProtocol.buildReadRecord(1), [0xB3, 0x01, 0x00]);
      expect(OneTouchProtocol.buildReadRecord(256), [0xB3, 0x00, 0x01]);
      expect(OneTouchProtocol.buildReadRecord(65535), [0xB3, 0xFF, 0xFF]);
    });
  });

  group('OneTouchProtocol - response parsers', () {
    test('parseRtc converts seconds-since-2000 to DateTime', () {
      // 0 seconds since 2000-01-01 -> 2000-01-01 00:00:00 UTC
      final msg = <int>[0x06, 0x00, 0x00, 0x00, 0x00];
      final dt = OneTouchProtocol.parseRtc(msg);
      expect(dt.toUtc().year, 2000);
      expect(dt.toUtc().month, 1);
      expect(dt.toUtc().day, 1);
    });

    test('parseRtc handles a known timestamp', () {
      // 1 day = 86400 seconds since 2000-01-01 = 2000-01-02 00:00:00 UTC
      final seconds = 86400;
      final msg = <int>[
        0x06,
        seconds & 0xFF,
        (seconds >> 8) & 0xFF,
        (seconds >> 16) & 0xFF,
        (seconds >> 24) & 0xFF,
      ];
      final dt = OneTouchProtocol.parseRtc(msg);
      expect(dt.toUtc().year, 2000);
      expect(dt.toUtc().month, 1);
      expect(dt.toUtc().day, 2);
    });

    test('parseCounter reads LE uint32', () {
      final msg = <int>[0x06, 0x39, 0x30, 0x00, 0x00]; // 12345 LE
      expect(OneTouchProtocol.parseCounter(msg), 12345);
    });

    test('parseRecordCount reads LE uint16', () {
      final msg = <int>[0x06, 0x64, 0x00]; // 100 LE
      expect(OneTouchProtocol.parseRecordCount(msg), 100);
    });

    test('parseParameter reads single byte', () {
      expect(OneTouchProtocol.parseParameter([0x06, 0x00]), 0); // mg/dL
      expect(OneTouchProtocol.parseParameter([0x06, 0x01]), 1); // mmol/L
    });
  });

  group('OneTouchProtocol - record parsing', () {
    OneTouchRecord? parseRecordBytes({
      required int seq,
      required int secondsSince2000,
      required int glucose,
      int controlFlag = 0,
      int mealFlag = 0,
      int rawByte10 = 0,
    }) {
      final msg = <int>[
        0x06, // status OK
        secondsSince2000 & 0xFF,
        (secondsSince2000 >> 8) & 0xFF,
        (secondsSince2000 >> 16) & 0xFF,
        (secondsSince2000 >> 24) & 0xFF,
        glucose & 0xFF,
        (glucose >> 8) & 0xFF,
        controlFlag,
        0x00, 0x00, // counter
        mealFlag,
        rawByte10,
      ];
      return OneTouchProtocol.parseRecord(msg, seq);
    }

    test('parses a normal blood glucose reading', () {
      final r = parseRecordBytes(
        seq: 42,
        secondsSince2000: 735_000_000, // ~2023-04-01
        glucose: 120,
        mealFlag: 1, // before meal
      );
      expect(r, isNotNull);
      expect(r!.sequenceNumber, 42);
      expect(r.glucoseMgDl, 120);
      expect(r.isControlSolution, false);
      expect(r.mealFlag, 1);
      // 735_000_000 seconds since 2000-01-01 = roughly April 2023
      expect(r.timestamp.toUtc().year, 2023);
    });

    test('skips control-solution records (controlFlag != 0)', () {
      // Control solution records are kept (parsed) but flagged isControlSolution=true;
      // the sync service filters them out before adding to the UI list.
      final r = parseRecordBytes(
        seq: 1,
        secondsSince2000: 0,
        glucose: 100,
        controlFlag: 1,
      );
      expect(r, isNotNull);
      expect(r!.isControlSolution, true);
    });

    test('rejects out-of-range glucose values', () {
      // 5 mg/dL — below the 20..600 sanity range
      expect(
        parseRecordBytes(seq: 1, secondsSince2000: 0, glucose: 5),
        isNull,
      );
      // 700 mg/dL — above the range
      expect(
        parseRecordBytes(seq: 1, secondsSince2000: 0, glucose: 700),
        isNull,
      );
    });

    test('rejects non-OK status byte', () {
      final msg = <int>[
        0x07, // UNAUTHORIZED
        0, 0, 0, 0, // timestamp
        120, 0, // glucose
        0, // control
        0, 0, // counter
        0, // meal
        0, // raw10
      ];
      expect(OneTouchProtocol.parseRecord(msg, 1), isNull);
    });

    test('rejects too-short message', () {
      final msg = <int>[0x06, 0, 0, 0, 0, 120, 0]; // only 7 bytes
      expect(OneTouchProtocol.parseRecord(msg, 1), isNull);
    });
  });

  group('OneTouchRecord.toReadingMap', () {
    test('builds deterministic id from meterId + sequence', () {
      final r = OneTouchRecord(
        sequenceNumber: 42,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        glucoseMgDl: 100,
        isControlSolution: false,
        mealFlag: 1,
        rawByte10: 0,
      );
      final map = r.toReadingMap(meterId: 'AB12CD34EF');
      expect(map['id'], 'onetouch_AB12CD34EF_42');
      expect(map['value'], 100);
      expect(map['type'], 'before_meal');
    });

    test('meal flag 2 maps to after_meal', () {
      final r = OneTouchRecord(
        sequenceNumber: 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        glucoseMgDl: 100,
        isControlSolution: false,
        mealFlag: 2,
        rawByte10: 0,
      );
      expect(r.toReadingMap(meterId: 'm')['type'], 'after_meal');
    });

    test('meal flag 0 maps to other', () {
      final r = OneTouchRecord(
        sequenceNumber: 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        glucoseMgDl: 100,
        isControlSolution: false,
        mealFlag: 0,
        rawByte10: 0,
      );
      expect(r.toReadingMap(meterId: 'm')['type'], 'other');
    });
  });
}
