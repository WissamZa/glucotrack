// OneTouch Select Plus Flex BLE protocol — pure Dart, no Flutter deps.
//
// Reverse-engineered from public sources:
//   - xDrip VerioHelper.java (Apache-2.0)
//   - xavaro BlueToothGlucoseOneTouch.java (GPL-3.0)
//   - glucometerutils protocols.glucometers.tech (MIT)
//
// The meter does NOT expose the standard Bluetooth SIG Glucose Service (0x1808).
// It uses a vendor-private service with a custom AES-128-ECB application-layer
// authentication handshake on top of BLE bonding.
//
// All multi-byte integers on the wire are LITTLE-ENDIAN.
import 'dart:typed_data';

import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/api.dart';

/// GATT UUIDs used by every LifeScan "Verio family" meter
/// (Select Plus Flex, Verio Flex, Verio Reflect, Ultra Plus Flex).
class OneTouchUuids {
  OneTouchUuids._();

  /// Vendor service — advertised by the meter.
  static const String service =
      'af9df7a1-e595-11e3-96b4-0002a5d5c51b';

  /// Command channel — client writes framed commands here.
  static const String write =
      'af9df7a2-e595-11e3-96b4-0002a5d5c51b';

  /// Response channel — meter pushes notifications here.
  static const String notify =
      'af9df7a3-e595-11e3-96b4-0002a5d5c51b';

  /// Standard CCCD descriptor UUID used to enable notifications.
  static const String cccd =
      '00002902-0000-1000-8000-00805f9b34fb';
}

/// Opcodes used in the LifeScan Verio command set.
///
/// Most opcodes are 1 byte; some take 1-2 selector bytes.
/// See docs/BLE_PROTOCOL.md for the full table.
class OneTouchOpcode {
  OneTouchOpcode._();
  static const int queryChallenge = 0xE6; // + [0x02, 0x08] -> challenge
  static const int enableFeatures = 0x11; // + 16-byte AES token -> status
  static const int readParameter = 0x09; //  + [0x02, selector]
  static const int readRtc = 0x20; //       + [0x02] -> uint32 sec since 2000
  static const int writeRtc = 0x20; //      + [0x01, ts4]
  static const int readCounter = 0x0A; //   + [0x02, selector]
  static const int readRecordCount = 0x27; //+ [0x00] -> uint16
  static const int readRecord = 0xB3; //    + [lo, hi] -> 11-byte record
  static const int eraseMemory = 0x1A; //   DANGEROUS — do not use
}

/// Selectors for the 0x0A readCounter opcode.
class OneTouchCounterSelector {
  OneTouchCounterSelector._();
  static const int testCount = 0x06; // uint32 LE — lifetime test count
  static const int lowRange = 0x07; //  uint32 LE — mg/dL low threshold
  static const int highRange = 0x08; // uint32 LE — mg/dL high threshold
}

/// Selectors for the 0x09 readParameter opcode.
class OneTouchParameterSelector {
  OneTouchParameterSelector._();
  static const int glucoseUnit = 0x02; // 0 = mg/dL, 1 = mmol/L
}

/// Status byte returned at the start of every response message.
class OneTouchStatus {
  OneTouchStatus._();
  static const int ok = 0x06;
  static const int unauthorized = 0x07;
  static const int unsupported = 0x08;
  static const int invalidValue = 0x09;
  static const int failed = 0x0F;

  static String name(int v) {
    switch (v) {
      case ok:
        return 'OK';
      case unauthorized:
        return 'UNAUTHORIZED';
      case unsupported:
        return 'UNSUPPORTED';
      case invalidValue:
        return 'INVALID_VALUE';
      case failed:
        return 'FAILED';
      default:
        return 'UNKNOWN(0x${v.toRadixString(16).padLeft(2, '0')})';
    }
  }
}

/// CRC-16/CCITT-FALSE: poly 0x1021, init 0xFFFF, no reflection, no xor-out.
///
/// Test vector: crc16ccitt('123456789'.codeUnits) == 0x29B1.
int crc16ccitt(List<int> data) {
  int crc = 0xFFFF;
  for (final byte in data) {
    crc ^= (byte & 0xFF) << 8;
    for (var i = 0; i < 8; i++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc & 0xFFFF;
}

/// LifeScan shared binary framing.
///
/// Wire layout:
///   STX(0x02) | length | linkCtrl(0x00) | cmdPrefix(0x03) | message | ETX(0x03) | CRC16_LE
/// where length = total packet length (7 + message.length) including STX and CRC.
class OneTouchFraming {
  OneTouchFraming._();

  static const int stx = 0x02;
  static const int etx = 0x03;
  static const int linkControl = 0x00;
  static const int commandPrefix = 0x03;

  /// Wrap a message in a framed packet (no BLE transport header).
  static Uint8List frame(List<int> message) {
    final length = 7 + message.length;
    final packet = <int>[
      stx,
      length,
      linkControl,
      commandPrefix,
      ...message,
      etx,
    ];
    final crc = crc16ccitt(packet);
    packet.add(crc & 0xFF);
    packet.add((crc >> 8) & 0xFF);
    return Uint8List.fromList(packet);
  }

  /// Strip framing and verify CRC. Returns the message bytes, or null on
  /// framing/CRC error.
  static List<int>? unframe(List<int> packet) {
    if (packet.length < 6) return null;
    if (packet[0] != stx) return null;
    final length = packet[1];
    if (packet.length != length) return null;
    if (packet[length - 3] != etx) return null;
    final crcBytes = packet.sublist(0, length - 2);
    final expected = crc16ccitt(crcBytes);
    final actual = (packet[length - 2] & 0xFF) | ((packet[length - 1] & 0xFF) << 8);
    if (expected != actual) return null;
    return packet.sublist(4, length - 3);
  }
}

/// BLE transport layer on top of LifeScan framing.
///
/// Each GATT write/notification carries a 1-byte packet header followed by
/// (a chunk of) a framed packet. The header's top 2 bits identify the packet
/// type; the low 6 bits carry a count or index.
///
///   0x00 | n  -> first data packet, n = total packet count (1..63)
///   0x40 | i  -> continuation data packet, i = 0-based index
///   0x80 | n  -> ACK byte (non-final), n = packet number
///   0xC0 | n  -> ACK byte (final), n = packet number
///
/// For Verio commands every response fits in a single packet, so the common
/// case is: TX = [0x01, ...framed], RX = [0x01, ...framed], ACK = [0x81].
class OneTouchTransport {
  OneTouchTransport._();

  /// Build the single-packet TX for a command. All Verio commands are small
  /// enough to fit in one packet, so we don't bother with multi-packet TX.
  static Uint8List buildTx(List<int> message) {
    final framed = OneTouchFraming.frame(message);
    return Uint8List.fromList([0x01, ...framed]); // 0x01 = "1 packet total"
  }

  /// Parse a notification. Returns the unframed message, or null if the
  /// notification is an ACK byte or a multi-packet continuation (we don't
  /// support multi-packet RX for MVP — all Verio responses are single-packet).
  static List<int>? parseRx(List<int> data) {
    if (data.isEmpty) return null;
    final header = data[0] & 0xFF;

    // ACK byte from meter (we don't expect these, but ignore them if they arrive)
    if ((header & 0xC0) == 0x80 || (header & 0xC0) == 0xC0) return null;

    // First data packet
    if ((header & 0xC0) == 0x00) {
      final total = header & 0x3F;
      if (total != 1) {
        // Multi-packet response — not supported in MVP. Caller will see null
        // and the sync will abort with a clear error message.
        return null;
      }
      final framed = data.sublist(1);
      return OneTouchFraming.unframe(framed);
    }

    // Continuation packet (0x40 | i) without a preceding first packet — ignore
    return null;
  }

  /// Build the ACK byte the client must write after each data notification.
  ///
  /// xDrip uses {0x81} for the single-packet case and it's known to work
  /// against the Select Plus Flex, so we match that exactly.
  static Uint8List buildAck() => Uint8List.fromList([0x81]);
}

/// AES-128-ECB application-layer authentication.
///
/// The OneTouch Reveal app performs this handshake on every connection; xDrip
/// skips it and still works against already-bonded meters. We implement it so
/// the sync is robust against firmware variants that require it.
class OneTouchAuth {
  OneTouchAuth._();

  /// Static AES-128 key extracted from the OneTouch Reveal APK by the xavaro
  /// project (deobfuscated via Simple.dezify() XOR with pattern 0x09, 0x05,
  /// 0x09, 0x02 on the low nibble).
  static final Uint8List key = Uint8List.fromList([
    0x48, 0x3b, 0xd3, 0xc2, 0xcb, 0xdf, 0x63, 0x45,
    0x16, 0x00, 0x04, 0xe6, 0xd5, 0x6d, 0x94, 0x8c,
  ]);

  /// Convert the meter's 16-byte challenge into the 16-byte AES token to send
  /// back in the EnableFeatures command.
  ///
  /// Algorithm (matches xavaro makeCipherToken):
  ///   1. rchallenge = challenge.reversed()
  ///   2. fchallenge[0..1] = rchallenge[2..3]
  ///      fchallenge[2..5] = rchallenge[4..7]
  ///      fchallenge[6..7] = rchallenge[0..1]
  ///      fchallenge[8..15] = fchallenge[0..7]  (duplicate first half)
  ///   3. token = AES-128-ECB(fchallenge, key)
  static Uint8List computeToken(Uint8List challenge) {
    if (challenge.length != 16) {
      throw ArgumentError(
        'Challenge must be 16 bytes, got ${challenge.length}',
      );
    }

    final r = challenge.reversed.toList();
    final f = Uint8List(16);
    f[0] = r[2];
    f[1] = r[3];
    f[2] = r[4];
    f[3] = r[5];
    f[4] = r[6];
    f[5] = r[7];
    f[6] = r[0];
    f[7] = r[1];
    for (var i = 0; i < 8; i++) {
      f[8 + i] = f[i];
    }

    final aes = AESEngine();
    aes.init(true, KeyParameter(key));
    final out = Uint8List(16);
    aes.processBlock(f, 0, out, 0);
    return out;
  }

  /// Decode the UTF-16LE hex string the meter returns as its challenge.
  ///
  /// The meter sends 32 UTF-16LE code units encoding ASCII hex characters
  /// (e.g. "A1B2C3D4E5F6A7B8" as 32 UTF-16LE bytes), which represents 16
  /// hex bytes. We parse it back to a 16-byte Uint8List.
  static Uint8List parseChallenge(List<int> raw) {
    // raw includes the status byte (0x06) at offset 0. Skip it.
    if (raw.isEmpty) return Uint8List(0);
    final payload = raw.sublist(1);

    // Decode UTF-16LE pairs into ASCII characters.
    final sb = StringBuffer();
    for (var i = 0; i + 1 < payload.length; i += 2) {
      final codeUnit = (payload[i] & 0xFF) | ((payload[i + 1] & 0xFF) << 8);
      if (codeUnit > 0x7F) {
        // Non-ASCII — abort
        return Uint8List(0);
      }
      sb.writeCharCode(codeUnit);
    }
    final hexStr = sb.toString();

    // Hex-decode the string (2 chars per byte -> 16 bytes)
    if (hexStr.length != 32) return Uint8List(0);
    final out = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      final byteStr = hexStr.substring(i * 2, i * 2 + 2);
      final v = int.tryParse(byteStr, radix: 16);
      if (v == null) return Uint8List(0);
      out[i] = v;
    }
    return out;
  }
}

/// A parsed glucose record from the meter.
class OneTouchRecord {
  final int sequenceNumber;
  final DateTime timestamp;
  final int glucoseMgDl;
  final bool isControlSolution;
  final int mealFlag; // 0=none, 1=before meal, 2=after meal
  final int rawByte10; // sensor_status / mentor metadata

  const OneTouchRecord({
    required this.sequenceNumber,
    required this.timestamp,
    required this.glucoseMgDl,
    required this.isControlSolution,
    required this.mealFlag,
    required this.rawByte10,
  });

  @override
  String toString() =>
      'OneTouchRecord(seq=$sequenceNumber, ts=$timestamp, glucose=$glucoseMgDl mg/dL, '
      'control=$isControlSolution, meal=$mealFlag)';

  /// Convert to GlucoTrack's `Reading` model fields.
  ///
  /// `id` is built deterministically from the meter serial + sequence number
  /// so re-syncing doesn't create duplicates.
  Map<String, dynamic> toReadingMap({required String meterId}) {
    return {
      'id': 'onetouch_${meterId}_$sequenceNumber',
      'value': glucoseMgDl,
      'type': _mealFlagToReadingType(mealFlag),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': null,
      'carbs': null,
      'insulin': null,
    };
  }

  static String _mealFlagToReadingType(int mealFlag) {
    switch (mealFlag) {
      case 1:
        return 'before_meal';
      case 2:
        return 'after_meal';
      default:
        return 'other';
    }
  }
}

/// Command builders + record parsing.
class OneTouchProtocol {
  OneTouchProtocol._();

  /// Seconds between Unix epoch (1970-01-01) and the meter epoch (2000-01-01).
  static const int meterEpochOffset = 946684800;

  /// Build the QUERY CHALLENGE command: {0xE6, 0x02, 0x08}.
  static List<int> buildQueryChallenge() =>
      [OneTouchOpcode.queryChallenge, 0x02, 0x08];

  /// Build the ENABLE FEATURES command: {0x11, <16-byte token>}.
  static List<int> buildEnableFeatures(Uint8List token) =>
      [OneTouchOpcode.enableFeatures, ...token];

  /// Build the READ RTC command: {0x20, 0x02}.
  static List<int> buildReadRtc() => [OneTouchOpcode.readRtc, 0x02];

  /// Build the READ COUNTER command: {0x0A, 0x02, selector}.
  static List<int> buildReadCounter(int selector) =>
      [OneTouchOpcode.readCounter, 0x02, selector];

  /// Build the READ PARAMETER command: {0x09, 0x02, selector}.
  static List<int> buildReadParameter(int selector) =>
      [OneTouchOpcode.readParameter, 0x02, selector];

  /// Build the READ RECORD COUNT command: {0x27, 0x00}.
  static List<int> buildReadRecordCount() =>
      [OneTouchOpcode.readRecordCount, 0x00];

  /// Build the READ RECORD command: {0xB3, lo, hi}.
  static List<int> buildReadRecord(int sequenceNumber) => [
        OneTouchOpcode.readRecord,
        sequenceNumber & 0xFF,
        (sequenceNumber >> 8) & 0xFF,
      ];

  /// Parse a READ RTC response into a DateTime.
  ///
  /// Message layout (after status byte):
  ///   bytes 1..4  LE uint32 — seconds since 2000-01-01 00:00:00 UTC
  static DateTime parseRtc(List<int> message) {
    if (message.length < 5) {
      throw FormatException('RTC response too short: ${message.length} bytes');
    }
    final bd = ByteData.sublistView(Uint8List.fromList(message.sublist(1, 5)));
    final seconds = bd.getUint32(0, Endian.little);
    return DateTime.fromMillisecondsSinceEpoch(
      (seconds + meterEpochOffset) * 1000,
      isUtc: true,
    ).toLocal();
  }

  /// Parse a READ COUNTER response into a uint32.
  static int parseCounter(List<int> message) {
    if (message.length < 5) {
      throw FormatException(
          'Counter response too short: ${message.length} bytes');
    }
    final bd = ByteData.sublistView(Uint8List.fromList(message.sublist(1, 5)));
    return bd.getUint32(0, Endian.little);
  }

  /// Parse a READ RECORD COUNT response into a uint16.
  static int parseRecordCount(List<int> message) {
    if (message.length < 3) {
      throw FormatException(
        'Record-count response too short: ${message.length} bytes',
      );
    }
    final bd = ByteData.sublistView(Uint8List.fromList(message.sublist(1, 3)));
    return bd.getUint16(0, Endian.little);
  }

  /// Parse a READ PARAMETER response (single byte value).
  static int parseParameter(List<int> message) {
    if (message.length < 2) {
      throw FormatException(
        'Parameter response too short: ${message.length} bytes',
      );
    }
    return message[1] & 0xFF;
  }

  /// Parse a READ RECORD response into a [OneTouchRecord].
  ///
  /// Wire layout (after status byte 0x06):
  ///   bytes 0..3   timestamp — LE uint32 sec since 2000-01-01
  ///   bytes 4..5   glucose  — LE int16 mg/dL (range 20..600)
  ///   byte  6      control_solution_flag — 0=blood, 1=control solution
  ///   bytes 7..8   counter/metadata — LE uint16 (Verio Reflect: mentor data)
  ///   byte  9      meal_flag — 0=none, 1=before meal, 2=after meal
  ///   byte  10     sensor_status / other_flags
  static OneTouchRecord? parseRecord(List<int> message, int sequenceNumber) {
    // message[0] is the status byte (0x06 = OK)
    if (message.isEmpty) return null;
    final status = message[0] & 0xFF;
    if (status != OneTouchStatus.ok) return null;

    // Payload starts at offset 1, must be at least 11 bytes
    if (message.length < 12) return null;
    final payload = message.sublist(1, 12);

    final bd = ByteData.sublistView(Uint8List.fromList(payload));
    final seconds = bd.getUint32(0, Endian.little);
    final glucose = bd.getInt16(4, Endian.little);
    final controlFlag = payload[6] & 0xFF;
    final mealFlag = payload[9] & 0xFF;
    final rawByte10 = payload[10] & 0xFF;

    // Sanity check: glucose must be in plausible range
    if (glucose < 20 || glucose > 600) return null;

    return OneTouchRecord(
      sequenceNumber: sequenceNumber,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (seconds + meterEpochOffset) * 1000,
        isUtc: true,
      ).toLocal(),
      glucoseMgDl: glucose,
      isControlSolution: controlFlag != 0,
      mealFlag: mealFlag,
      rawByte10: rawByte10,
    );
  }
}
