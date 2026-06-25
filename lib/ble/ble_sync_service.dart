// OneTouch Select Plus Flex BLE sync service.
//
// Wraps flutter_blue_plus and implements the xDrip-style sync flow:
//   1. Scan for devices advertising the OneTouch vendor service OR named "OneTouch*"
//   2. Connect, discover services
//   3. Subscribe to notifications on af9df7a3
//   4. Read meter RTC, test count, record count
//   5. Loop: ReadRecord(i) for i = test_count down to (test_count - record_count + 1)
//   6. Return list of [OneTouchRecord]
//
// All GATT writes are strictly serialized: one command outstanding at a time,
// wait for the data notification + ACK before sending the next.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'onetouch_protocol.dart';

/// Progress callback. `fraction` is 0.0..1.0, `message` is a human-readable
/// status line for the UI.
typedef ProgressCallback = void Function(double fraction, String message);

/// Log callback for debug lines.
typedef LogCallback = void Function(String line);

/// Phase the sync state machine is in — surfaced to the UI.
enum SyncPhase {
  idle,
  scanning,
  connecting,
  discovering,
  subscribing,
  readingMetadata,
  readingRecords,
  done,
  error,
}

/// State snapshot for the UI to render.
class SyncState {
  final SyncPhase phase;
  final String message;
  final double fraction;
  final List<OneTouchRecord> records;
  final String? error;

  const SyncState({
    this.phase = SyncPhase.idle,
    this.message = '',
    this.fraction = 0,
    this.records = const [],
    this.error,
  });

  SyncState copyWith({
    SyncPhase? phase,
    String? message,
    double? fraction,
    List<OneTouchRecord>? records,
    String? error,
  }) =>
      SyncState(
        phase: phase ?? this.phase,
        message: message ?? this.message,
        fraction: fraction ?? this.fraction,
        records: records ?? this.records,
        error: error ?? this.error,
      );
}

/// A discovered OneTouch meter.
class DiscoveredMeter {
  final BluetoothDevice device;
  final String name;
  final String remoteId;

  const DiscoveredMeter({
    required this.device,
    required this.name,
    required this.remoteId,
  });
}

/// Main BLE sync service. One instance per session — create, use, dispose.
class OneTouchBleService {
  OneTouchBleService({
    this.commandTimeout = const Duration(seconds: 5),
    this.scanTimeout = const Duration(seconds: 10),
  }) {
    // adapterState subscription lets us detect Bluetooth being turned off
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on && _state.phase != SyncPhase.idle) {
        _emitError('Bluetooth adapter is off ($state)');
      }
    });
  }

  /// Per-command timeout. If the meter doesn't respond within this window
  /// we abort the sync with an error.
  final Duration commandTimeout;

  /// How long to scan before giving up.
  final Duration scanTimeout;

  StreamController<SyncState>? _stateCtl = StreamController<SyncState>.broadcast();
  StreamController<String>? _logCtl = StreamController<String>.broadcast();

  late StreamSubscription<BluetoothAdapterState> _adapterSub;
  StreamSubscription? _resultsSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  SyncState _state = const SyncState();
  SyncState get state => _state;

  /// Stream of state snapshots for the UI.
  Stream<SyncState> get stateStream => _stateCtl!.stream;

  /// Stream of debug log lines for the UI.
  Stream<String> get logStream => _logCtl!.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  Completer<List<int>>? _pendingResponse;
  int _nextSeq = 0;

  // ============== Public API ==============

  /// Scan for OneTouch meters nearby. Returns a future that resolves with
  /// the list of discovered devices when the scan completes (or after
  /// [scanTimeout]).
  Future<List<DiscoveredMeter>> scan() async {
    _emit(phase: SyncPhase.scanning, message: 'Scanning for OneTouch meters…');
    final found = <DiscoveredMeter>[];
    final seen = <String>{};

    // Subscribe BEFORE starting the scan so we don't miss early results.
    // We filter by name prefix "OneTouch" in code rather than by service UUID
    // in the scan filter, because some Verio-family meters don't reliably
    // advertise the 128-bit service UUID in their advertisement packet.
    _resultsSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName;
        if (name.isEmpty) continue;
        if (!name.startsWith('OneTouch')) continue;
        final id = r.device.remoteId.str;
        if (seen.contains(id)) continue;
        seen.add(id);
        found.add(DiscoveredMeter(
          device: r.device,
          name: name,
          remoteId: id,
        ),);
        _log('Found $name ($id)');
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        // No withServices filter — we match by name prefix instead.
      );
      // startScan with timeout completes when the scan finishes.
    } finally {
      await _resultsSub?.cancel();
      _resultsSub = null;
    }

    _emit(
      phase: SyncPhase.idle,
      message: found.isEmpty
          ? 'No OneTouch meters found.'
          : 'Found ${found.length} meter(s).',
    );
    return found;
  }

  /// Connect to [meter], run the full sync, and return the list of records.
  Future<List<OneTouchRecord>> syncWith(DiscoveredMeter meter) async {
    try {
      await _connect(meter);
      await _subscribe();
      final records = await _readAllRecords();
      _emit(
        phase: SyncPhase.done,
        message: 'Sync complete: ${records.length} record(s).',
        fraction: 1.0,
        records: records,
      );
      return records;
    } catch (e, st) {
      _log('Sync failed: $e\n$st');
      _emitError(e.toString());
      rethrow;
    } finally {
      await disconnect();
    }
  }

  /// Disconnect from the meter and cancel all subscriptions.
  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    await _connSub?.cancel();
    _connSub = null;
    try {
      await _connectedDevice?.disconnect();
    } on Exception catch (_) {
      // Best-effort disconnect
    }
    _connectedDevice = null;
    _writeChar = null;
    _notifyChar = null;
  }

  /// Release all resources. Call when the UI is disposed.
  void dispose() {
    disconnect();
    _adapterSub.cancel();
    _stateCtl?.close();
    _logCtl?.close();
    _stateCtl = null;
    _logCtl = null;
  }

  // ============== Internals ==============

  Future<void> _connect(DiscoveredMeter meter) async {
    _emit(phase: SyncPhase.connecting, message: 'Connecting to ${meter.name}…');
    _connectedDevice = meter.device;
    _connSub = meter.device.connectionState.listen((state) {
      _log('Connection state: $state');
      if (state == BluetoothConnectionState.disconnected &&
          _state.phase != SyncPhase.done &&
          _state.phase != SyncPhase.error) {
        _emitError('Device disconnected unexpectedly');
      }
    });

    await meter.device.connect(license: License.nonprofit, timeout: const Duration(seconds: 15));

    _emit(phase: SyncPhase.discovering, message: 'Discovering services…');
    final services = await meter.device.discoverServices();

    BluetoothService? service;
    BluetoothCharacteristic? writeChar;
    BluetoothCharacteristic? notifyChar;
    for (final s in services) {
      if (s.uuid == Guid(OneTouchUuids.service)) {
        service = s;
        for (final c in s.characteristics) {
          if (c.uuid == Guid(OneTouchUuids.write)) writeChar = c;
          if (c.uuid == Guid(OneTouchUuids.notify)) notifyChar = c;
        }
      }
    }

    if (service == null) {
      throw StateError(
        'OneTouch vendor service ${OneTouchUuids.service} not found. '
        'Is the meter paired?',
      );
    }
    if (writeChar == null || notifyChar == null) {
      throw StateError(
        'OneTouch write/notify characteristic missing. '
        'write=${writeChar != null}, notify=${notifyChar != null}',
      );
    }
    _writeChar = writeChar;
    _notifyChar = notifyChar;
    _log('Discovered OneTouch service with write + notify characteristics.');
  }

  Future<void> _subscribe() async {
    _emit(phase: SyncPhase.subscribing, message: 'Subscribing to notifications…');
    final notify = _notifyChar!;
    await notify.setNotifyValue(true);
    _notifySub = notify.lastValueStream.listen(_onNotify);
    // Give the BLE stack a moment to actually push the CCCD write to the meter
    await Future.delayed(const Duration(milliseconds: 300));
    _log('Notifications enabled.');
  }

  Future<List<OneTouchRecord>> _readAllRecords() async {
    _emit(
      phase: SyncPhase.readingMetadata,
      message: 'Reading meter time…',
    );
    final meterTime = await _readRtc();
    _log('Meter time: $meterTime');

    _emit(message: 'Reading test count…');
    final testCount = await _readCounter(OneTouchCounterSelector.testCount);
    _log('Lifetime test count: $testCount');

    _emit(message: 'Reading record count…');
    final recordCount = await _readRecordCount();
    _log('Records in memory: $recordCount');

    if (recordCount == 0 || testCount == 0) {
      _emit(
        phase: SyncPhase.readingRecords,
        message: 'Meter has no records.',
        fraction: 1.0,
        records: const [],
      );
      return const [];
    }

    final startSeq = testCount - recordCount + 1;
    final records = <OneTouchRecord>[];
    var fetched = 0;

    _emit(
      phase: SyncPhase.readingRecords,
      message: 'Reading record 1 of $recordCount…',
      fraction: 0.0,
    );

    for (var seq = testCount; seq >= startSeq; seq--) {
      _emit(
        message: 'Reading record ${fetched + 1} of $recordCount…',
        fraction: fetched / recordCount,
      );
      final record = await _readRecord(seq);
      if (record != null && !record.isControlSolution) {
        records.add(record);
        _log('  seq=$seq glucose=${record.glucoseMgDl} mg/dL @ ${record.timestamp}');
      } else if (record != null && record.isControlSolution) {
        _log('  seq=$seq skipped (control solution)');
      }
      fetched++;
    }

    _emit(
      message: 'Synced ${records.length} record(s).',
      fraction: 1.0,
      records: records,
    );
    return records;
  }

  Future<DateTime> _readRtc() async {
    final msg = await _sendCommand(OneTouchProtocol.buildReadRtc());
    return OneTouchProtocol.parseRtc(msg);
  }

  Future<int> _readCounter(int selector) async {
    final msg = await _sendCommand(OneTouchProtocol.buildReadCounter(selector));
    return OneTouchProtocol.parseCounter(msg);
  }

  Future<int> _readRecordCount() async {
    final msg = await _sendCommand(OneTouchProtocol.buildReadRecordCount());
    return OneTouchProtocol.parseRecordCount(msg);
  }

  Future<OneTouchRecord?> _readRecord(int sequenceNumber) async {
    final msg = await _sendCommand(
      OneTouchProtocol.buildReadRecord(sequenceNumber),
    );
    return OneTouchProtocol.parseRecord(msg, sequenceNumber);
  }

  /// Send a command and wait for the meter's data notification.
  Future<List<int>> _sendCommand(List<int> message) async {
    if (_writeChar == null) {
      throw StateError('Not connected');
    }
    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      throw StateError('Command already in flight');
    }
    final completer = Completer<List<int>>();
    _pendingResponse = completer;
    final mySeq = ++_nextSeq;

    final tx = OneTouchTransport.buildTx(message);
    _log('TX[$mySeq]: ${_hex(tx)}');
    await _writeChar!.write(tx, withoutResponse: false);

    final result = await completer.future.timeout(commandTimeout, onTimeout: () {
      throw TimeoutException(
        'Meter did not respond within ${commandTimeout.inSeconds}s '
        'to command ${_hex(message)}',
      );
    },);
    _log('RX[$mySeq]: ${_hex(Uint8List.fromList(result))}');
    return result;
  }

  /// Notification handler — parse the incoming packet, send the ACK, and
  /// complete the pending response future.
  void _onNotify(List<int> data) {
    final parsed = OneTouchTransport.parseRx(data);
    if (parsed == null) {
      // Either an ACK byte from the meter (unexpected but harmless) or an
      // unsupported multi-packet notification. Either way, ignore.
      _log('RX (ignoring): ${_hex(Uint8List.fromList(data))}');
      return;
    }

    // Send ACK back to the meter for the data packet we just received.
    // Fire-and-forget — if this write fails we'll fail on the next command.
    final ack = OneTouchTransport.buildAck();
    _writeChar?.write(ack, withoutResponse: false).catchError((e) {
      _log('ACK write failed: $e');
    });

    // Complete the pending response future.
    final p = _pendingResponse;
    if (p != null && !p.isCompleted) {
      p.complete(parsed);
    } else {
      _log('Received data with no pending command: ${_hex(Uint8List.fromList(parsed))}');
    }
  }

  // ============== Helpers ==============

  void _emit({
    SyncPhase? phase,
    String? message,
    double? fraction,
    List<OneTouchRecord>? records,
  }) {
    _state = _state.copyWith(
      phase: phase,
      message: message,
      fraction: fraction,
      records: records,
    );
    _stateCtl?.add(_state);
  }

  void _emitError(String error) {
    _state = SyncState(
      phase: SyncPhase.error,
      message: error,
      error: error,
      records: _state.records,
    );
    _stateCtl?.add(_state);
  }

  void _log(String line) {
    if (kDebugMode) {
      final redacted = line.replaceAllMapped(
        RegExp(r'(challenge|token|key)[:\s]*([0-9a-fA-F]{16,})'),
        (m) => '${m[1]}: [REDACTED]',
      );
      // ignore: avoid_print
      print('[OneTouchBLE] $redacted');
      _logCtl?.add(redacted);
    }
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0')).join();
}
