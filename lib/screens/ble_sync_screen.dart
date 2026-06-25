// BLE sync screen — scan for OneTouch Select Plus Flex meters, connect,
// sync all glucose records, and persist them into GlucoTrack's SQLite DB.
//
// User flow:
//   1. Tap "Scan for meters"  (requires Bluetooth ON + permissions granted)
//   2. Pick a meter from the discovered list
//      → OS pairing dialog appears if not already bonded — enter 6-digit PIN
//   3. Progress card shows each sync phase
//   4. Review the synced records
//   5. Tap "Save to GlucoTrack" to persist (duplicate-safe via seq-number ID)
//
// Platform:  Android / iOS / macOS / Windows only.
//            Linux / Web → shows a graceful "not supported" screen.
import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// flutter_blue_plus is imported unconditionally; on unsupported platforms the
// entire BLE code path is behind an [isBleSupported] guard so the import is
// fine even if the plugin has no native implementation on that platform.
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../ble/ble_platform.dart';
import '../ble/ble_sync_service.dart';
import '../ble/onetouch_protocol.dart';
import '../database/database_helper.dart';
import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../utils/unit_converter.dart';


// ─────────────────────────────────────────────────────────────────────────────

class BleSyncScreen extends StatefulWidget {
  const BleSyncScreen({super.key});

  @override
  State<BleSyncScreen> createState() => _BleSyncScreenState();
}

class _BleSyncScreenState extends State<BleSyncScreen>
    with SingleTickerProviderStateMixin {
  OneTouchBleService? _service;

  // FIX-041 / PERF-005: Queue gives O(1) removeFirst vs O(n) removeRange on
  // List, important since the log stream can fire many times per second.
  final Queue<String> _logs = Queue<String>();
  final _scannedMeters = <DiscoveredMeter>[];

  bool _scanning = false;
  bool _syncing = false;
  bool _saved = false;

  final _selectedSeqs = <int>{};
  bool _selectionInitialized = false;

  SyncState _state = const SyncState();
  StreamSubscription<SyncState>? _stateSub;
  StreamSubscription<String>? _logSub;

  String _lastMeterRemoteId = 'unknown';

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    ); // started/stopped on demand by _startScan / scan completion (FIX-041 / PERF-006)
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (isBleSupported) {
      _service = OneTouchBleService();
      _stateSub = _service!.stateStream.listen((s) {
        if (mounted) setState(() => _state = s);
      });
      _logSub = _service!.logStream.listen((line) {
        if (mounted) {
          setState(() {
            _logs.addLast(line);
            if (_logs.length > 200) {
              _logs.removeFirst(); // O(1) on Queue vs O(n) on List
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _stateSub?.cancel();
    _logSub?.cancel();
    _service?.dispose();
    super.dispose();
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    final strings = AppStrings.of(context);
    setState(() {
      _scanning = true;
      _scannedMeters.clear();
      _saved = false;
    });
    // FIX-041 / PERF-006: only run the pulse animation while actively scanning.
    unawaited(_pulseCtrl.repeat(reverse: true));

    try {
      await _requestBlePermissions();

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (mounted) {
          _showSnack(strings.blePleaseEnableBt);
        }
        return;
      }

      final found = await _service!.scan();
      if (mounted) setState(() => _scannedMeters.addAll(found));

      if (mounted && found.isEmpty) {
        _showSnack(strings.bleNoMetersFound);
      }
    } on Exception catch (e) {
      if (mounted) _showSnack(strings.bleScanFailed(e));
    } finally {
      // Stop the pulse animation whenever scan ends (success, failure, or early return).
      _pulseCtrl.stop();
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _requestBlePermissions() async {
    if (kIsWeb) return;
    // Only Android needs runtime permission requests.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  Future<void> _syncWith(DiscoveredMeter meter) async {
    setState(() {
      _syncing = true;
      _saved = false;
      _logs.clear();
      _lastMeterRemoteId = meter.remoteId;
      _selectedSeqs.clear();
      _selectionInitialized = false;
    });

    try {
      await _service!.syncWith(meter);
    } on Exception catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveToGlucoTrack() async {
    final strings = AppStrings.of(context);
    final records = _state.records;
    if (records.isEmpty) return;

    final db = DatabaseHelper();
    final rProv = context.read<ReadingsProvider>();
    var inserted = 0;
    var skipped = 0;

    for (final rec in records) {
      if (!_selectedSeqs.contains(rec.sequenceNumber)) {
        continue;
      }
      final id =
          'onetouch_${_sanitize(_lastMeterRemoteId)}_${rec.sequenceNumber}';
      if (rProv.findById(id) != null) {
        skipped++;
        continue;
      }
      final reading = Reading(
        id: id,
        value: rec.glucoseMgDl,
        type: _mealFlagToReadingType(rec.mealFlag),
        timestamp: rec.timestamp,
        notes: strings.bleSyncedFromMeter,
      );
      await db.insertReading(reading);
      await rProv.add(reading);
      inserted++;
    }

    if (!mounted) return;
    setState(() {
      _saved = true;
      _selectedSeqs.clear();
    });
    _showSnack(strings.bleSaveResult(inserted, skipped));
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _reset() {
    setState(() {
      _state = const SyncState();
      _logs.clear();
      _saved = false;
      _scannedMeters.clear();
      _syncing = false;
      _selectedSeqs.clear();
      _selectionInitialized = false;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

  ReadingType _mealFlagToReadingType(int flag) {
    switch (flag) {
      case 1:
        return ReadingType.beforeMeal;
      case 2:
        return ReadingType.afterMeal;
      default:
        return ReadingType.other;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final strings = AppStrings.of(context);
    final rProv = context.watch<ReadingsProvider>();

    final records = _state.records;
    final isDone = _state.phase == SyncPhase.done;

    if (isDone && !_selectionInitialized && records.isNotEmpty) {
      _selectionInitialized = true;
      _selectedSeqs.clear();
      for (final rec in records) {
        final id = 'onetouch_${_sanitize(_lastMeterRemoteId)}_${rec.sequenceNumber}';
        final alreadySaved = rProv.findById(id) != null;
        if (!alreadySaved) {
          _selectedSeqs.add(rec.sequenceNumber);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.bleSyncTitle),
        actions: [
          IconButton(
            tooltip: strings.bleHelpTooltip,
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: !isBleSupported
          ? _buildUnsupportedView(primary)
          : (_syncing || _state.phase == SyncPhase.done || _state.phase == SyncPhase.error)
              ? _buildSyncView()
              : _buildScanView(primary),
    );
  }

  // ── Unsupported Platform ───────────────────────────────────────────────────

  Widget _buildUnsupportedView(Color primary) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bluetooth_disabled, size: 48, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              strings.bleUnavailableTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              bleUnsupportedReason ?? strings.bleUnavailableDesc,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.android),
              label: Text(strings.bleAvailablePlatforms),
              onPressed: null, // disabled — informational
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14,),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scan View ─────────────────────────────────────────────────────────────

  Widget _buildScanView(Color primary) {
    final strings = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(pulseAnim: _pulseAnim, primary: primary),
        const SizedBox(height: 16),
        if (_scanning)
          _ScanningCard(primary: primary)
        else
          _ScanButton(primary: primary, onPressed: _startScan),
        const SizedBox(height: 16),
        if (_scannedMeters.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              strings.bleMetersFound(_scannedMeters.length),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          for (final m in _scannedMeters) _MeterCard(meter: m, onTap: () => _syncWith(m)),
          const SizedBox(height: 8),
        ],
        const _PairingHint(),
      ],
    );
  }

  // ── Sync View ─────────────────────────────────────────────────────────────

  Widget _buildSyncView() {
    final s = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);
    final rProv = context.watch<ReadingsProvider>();
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final records = _state.records;
    final isDone = _state.phase == SyncPhase.done;
    final isError = _state.phase == SyncPhase.error;

    // Count how many are unsaved
    final unsavedRecords = records.where((rec) {
      final id = 'onetouch_${_sanitize(_lastMeterRemoteId)}_${rec.sequenceNumber}';
      return rProv.findById(id) == null;
    }).toList();

    final allSelected = unsavedRecords.isNotEmpty && unsavedRecords.every((rec) => _selectedSeqs.contains(rec.sequenceNumber));
    final someSelected = unsavedRecords.isNotEmpty && unsavedRecords.any((rec) => _selectedSeqs.contains(rec.sequenceNumber)) && !allSelected;

    // FIX-041 / PERF-005: _logs is a Queue — snapshot it to a List for indexed
    // access in the debug-log ListView below.
    final logList = _logs.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Progress card ──
        _ProgressCard(state: _state),
        const SizedBox(height: 16),

        // ── Record list ──
        if (records.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.bleSyncedRecords(records.length),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15,),
              ),
              if (!_saved && isDone)
                FilledButton.icon(
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: Text(strings.bleSaveSelected(_selectedSeqs.length)),
                  onPressed: _selectedSeqs.isEmpty ? null : _saveToGlucoTrack,
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (isDone && unsavedRecords.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          for (final rec in unsavedRecords) {
                            _selectedSeqs.add(rec.sequenceNumber);
                          }
                        } else {
                          for (final rec in unsavedRecords) {
                            _selectedSeqs.remove(rec.sequenceNumber);
                          }
                        }
                      });
                    },
                  ),
                  Text(
                    allSelected
                        ? strings.bleDeselectAllNew
                        : strings.bleSelectAllNew,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],

          for (final r in records) ...[
            (() {
              final id = 'onetouch_${_sanitize(_lastMeterRemoteId)}_${r.sequenceNumber}';
              final alreadySaved = rProv.findById(id) != null;
              final isSelected = _selectedSeqs.contains(r.sequenceNumber);
              return _RecordTile(
                record: r,
                settings: s,
                fmt: fmt,
                selected: isSelected,
                alreadySaved: alreadySaved,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSeqs.add(r.sequenceNumber);
                    } else {
                      _selectedSeqs.remove(r.sequenceNumber);
                    }
                  });
                },
              );
            })(),
          ],
          const SizedBox(height: 16),
        ],

        if (_saved)
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(strings.bleRecordsSaved),
            ),
          ),

        // ── Debug log ──
        // FIX-041 / PERF-005: logList is the List snapshot of the _logs Queue
        // (see top of _buildSyncView).
        ExpansionTile(
          leading: const Icon(Icons.terminal, size: 18),
          title: Text(strings.bleDebugLog(logList.length),
              style: const TextStyle(fontSize: 13),),
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: logList.length,
                itemBuilder: (_, i) => Text(
                  logList[i],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: Color(0xFF6EEB83),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        if (isDone || isError)
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(strings.bleStartOver),
            onPressed: _reset,
          ),
      ],
    );
  }

  // ── Help dialog ───────────────────────────────────────────────────────────

  void _showHelpDialog(BuildContext context) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.bleHelpTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpStep(n: '1', text: strings.bleHelpStep1),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(strings.bleHelpStep1Detail),
              ),
              _HelpStep(n: '2', text: strings.bleHelpStep2),
              _HelpStep(n: '3', text: strings.bleHelpStep3),
              _HelpStep(n: '4', text: strings.bleHelpStep4),
              _HelpStep(n: '5', text: strings.bleHelpStep5),
              _HelpStep(n: '6', text: strings.bleHelpStep6),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(strings.bleTips,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),),
              const SizedBox(height: 4),
              Text(
                strings.bleTipsText,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.bleGotIt),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Color primary;
  const _HeroCard({required this.pulseAnim, required this.primary});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: pulseAnim.value,
                child: child,
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bluetooth_connected, color: primary, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.bleHeroDevice,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.bleHeroDesc,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final Color primary;
  final VoidCallback onPressed;
  const _ScanButton({required this.primary, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return FilledButton.icon(
      icon: const Icon(Icons.bluetooth_searching),
      label: Text(strings.bleScanButton),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ScanningCard extends StatelessWidget {
  final Color primary;
  const _ScanningCard({required this.primary});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      elevation: 0,
      color: primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: primary,),
          ),
          const SizedBox(height: 14),
          Text(
            strings.bleScanning,
            style: TextStyle(fontWeight: FontWeight.w600, color: primary),
          ),
          const SizedBox(height: 4),
          Text(
            strings.bleScanningHint,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],),
      ),
    );
  }
}

class _MeterCard extends StatelessWidget {
  final DiscoveredMeter meter;
  final VoidCallback onTap;
  const _MeterCard({required this.meter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final strings = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.bloodtype, color: Colors.red, size: 22),
        ),
        title: Text(meter.name,
            style: const TextStyle(fontWeight: FontWeight.w600),),
        subtitle: Text(
          meter.remoteId,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(strings.bleConnect,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,),),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final SyncState state;
  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final strings = AppStrings.of(context);
    final isDone = state.phase == SyncPhase.done;
    final isError = state.phase == SyncPhase.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isError
              ? Colors.red.shade200
              : isDone
                  ? Colors.green.shade200
                  : primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _phaseIcon(isDone, isError, primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.message.isEmpty
                      ? _phaseLabel(state.phase, strings)
                      : state.message,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14,),
                ),
              ),
            ],),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: isError ? 0 : state.fraction,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                    isError ? Colors.red : isDone ? Colors.green : primary,),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isError
                  ? strings.bleFailed
                  : strings.blePercentComplete((state.fraction * 100).round()),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phaseIcon(bool isDone, bool isError, Color primary) {
    if (isDone) {
      return const Icon(Icons.check_circle_rounded,
          color: Colors.green, size: 22,);
    }
    if (isError) {
      return const Icon(Icons.error_rounded, color: Colors.red, size: 22);
    }
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
    );
  }

  String _phaseLabel(SyncPhase p, AppStrings strings) {
    switch (p) {
      case SyncPhase.idle:           return strings.blePhaseIdle;
      case SyncPhase.scanning:       return strings.blePhaseScanning;
      case SyncPhase.connecting:     return strings.blePhaseConnecting;
      case SyncPhase.discovering:    return strings.blePhaseDiscovering;
      case SyncPhase.subscribing:    return strings.blePhaseSubscribing;
      case SyncPhase.readingMetadata:return strings.blePhaseReadingMetadata;
      case SyncPhase.readingRecords: return strings.blePhaseReadingRecords;
      case SyncPhase.done:           return strings.blePhaseDone;
      case SyncPhase.error:          return strings.blePhaseError;
    }
  }
}

class _RecordTile extends StatelessWidget {
  final OneTouchRecord record;
  final Settings settings;
  final DateFormat fmt;
  final bool selected;
  final bool alreadySaved;
  final ValueChanged<bool?>? onChanged;

  const _RecordTile({
    required this.record,
    required this.settings,
    required this.fmt,
    required this.selected,
    required this.alreadySaved,
    required this.onChanged,
  });

  Color _glucoseColor(int mgDl, Settings s) {
    if (mgDl < s.targetMin) return Colors.orange;
    if (mgDl > s.targetMax) return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final color = _glucoseColor(record.glucoseMgDl, settings);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            UnitConverter.format(record.glucoseMgDl, settings.unit),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,),
          ),
        ),
        title: Text(
          '${UnitConverter.formatWithUnit(record.glucoseMgDl, settings.unit)}'
          '${record.isControlSolution ? ' ${strings.bleControlSolution}' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${fmt.format(record.timestamp)} · seq ${record.sequenceNumber}'
          '${record.mealFlag != 0 ? ' · ${_mealLabel(record.mealFlag, strings)}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: alreadySaved
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  strings.bleSaved,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Checkbox(
                value: selected,
                onChanged: onChanged,
              ),
      ),
    );
  }

  String _mealLabel(int flag, AppStrings strings) {
    switch (flag) {
      case 1:  return strings.bleBeforeMealShort;
      case 2:  return strings.bleAfterMealShort;
      default: return '';
    }
  }
}

class _PairingHint extends StatelessWidget {
  const _PairingHint();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.blePairingTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),),
                  const SizedBox(height: 4),
                  Text(
                    strings.blePairingDesc,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.brown.shade700,
                        height: 1.4,),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String n;
  final String text;
  const _HelpStep({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(n,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,),),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
