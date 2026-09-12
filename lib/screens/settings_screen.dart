import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../ble/ble_platform.dart';
import '../database/database_helper.dart';
import '../i18n/strings.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../services/drive_sync_service.dart';
import '../utils/backup_merge.dart';
import '../utils/export_import.dart';
import '../utils/unit_converter.dart';
import '../widgets/screen_padding.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: context.read<SettingsProviderState>().settings.userName,
    );
    // Real app version from the platform (pubspec version/name).
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) setState(() => _version = info.version);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProviderState>();
    final s = prov.settings;
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        // Bottom clearance for the MainShell BottomAppBar + gesture inset so
        // the last items are fully reachable.
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          tabBarBottomClearance(context),
        ),
        children: [
          _SectionTitle(strings.appearance),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.language,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _choiceBtn(
                        s.language == Language.ar,
                        '🇸🇦 العربية',
                        () => _update(prov, language: Language.ar),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choiceBtn(
                        s.language == Language.en,
                        '🇬🇧 English',
                        () => _update(prov, language: Language.en),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.displayStyle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _styleRow(
                  prov,
                  s,
                  ThemeStyle.classic,
                  strings.styleClassic,
                  Icons.medical_services,
                ),
                _styleRow(
                  prov,
                  s,
                  ThemeStyle.modern,
                  strings.styleModern,
                  Icons.nightlight,
                ),
                _styleRow(
                  prov,
                  s,
                  ThemeStyle.elder,
                  strings.styleElder,
                  Icons.wb_sunny,
                ),
              ],
            ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.glucoseUnit,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _choiceBtn(
                        s.unit == GlucoseUnit.mgDl,
                        strings.unitMg,
                        () => _update(prov, unit: GlucoseUnit.mgDl),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choiceBtn(
                        s.unit == GlucoseUnit.mmolL,
                        strings.unitMmol,
                        () => _update(prov, unit: GlucoseUnit.mmolL),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _SectionTitle(strings.health),
          // Insulin preference — controls whether the insulin dose field is
          // offered when adding a reading.
          _Card(
            child: Row(
              children: [
                Icon(
                  Icons.vaccines,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.usesInsulinLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        strings.usesInsulinHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: s.usesInsulin,
                  onChanged: (v) => _update(prov, usesInsulin: v),
                ),
              ],
            ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monitor_heart,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.diabetesType,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _choiceBtn(
                        s.diabetesType == DiabetesType.type1,
                        strings.get('diabetes_type1'),
                        () => _update(prov, diabetesType: DiabetesType.type1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _choiceBtn(
                        s.diabetesType == DiabetesType.type2,
                        strings.get('diabetes_type2'),
                        () => _update(prov, diabetesType: DiabetesType.type2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _choiceBtn(
                        s.diabetesType == DiabetesType.gestational,
                        strings.get('diabetes_gestational'),
                        () => _update(
                          prov,
                          diabetesType: DiabetesType.gestational,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${strings.glucoseTargets} (${UnitConverter.unitLabel(s.unit)})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.targetMin,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            // Re-keyed per unit so the initial value rebuilds
                            // when the user switches mg/dL ↔ mmol/L.
                            key: ValueKey('target_min_${s.unit}'),
                            initialValue: s.unit == GlucoseUnit.mgDl
                                ? '${s.targetMin}'
                                : UnitConverter.mgToMmol(s.targetMin)
                                      .toStringAsFixed(1),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              final mgDl = _parseGlucose(v, s.unit);
                              if (mgDl != null) {
                                _update(prov, targetMin: mgDl.clamp(40, 150));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.targetMax,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            key: ValueKey('target_max_${s.unit}'),
                            initialValue: s.unit == GlucoseUnit.mgDl
                                ? '${s.targetMax}'
                                : UnitConverter.mgToMmol(s.targetMax)
                                      .toStringAsFixed(1),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              final mgDl = _parseGlucose(v, s.unit);
                              if (mgDl != null) {
                                _update(prov, targetMax: mgDl.clamp(120, 300));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.height,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.heightCmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  strings.heightHint,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('height_${s.heightCm}'),
                  initialValue: s.heightCm != null
                      ? s.heightCm!.toStringAsFixed(0)
                      : '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    final n = double.tryParse(v.trim());
                    if (n != null) {
                      _update(prov, heightCm: n.clamp(80.0, 250.0));
                    }
                  },
                ),
              ],
            ),
          ),

          _SectionTitle(strings.profile),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _update(prov, userName: _nameCtrl.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.saveSettings)),
                        );
                      },
                      child: Text(strings.save),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _SectionTitle(strings.exportData),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/export'),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.exportData,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              strings.importData,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _SectionTitle(strings.integrations),
          const _DriveSyncCard(),
          // ── BLE Meter Sync — LIVE ─────────────────────────────────────
          _Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pushNamed('/sync'),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bluetooth_connected,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.deviceIntegration,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'OneTouch Select Plus Flex',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Platform badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isBleSupported
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isBleSupported ? 'Available' : 'Android only',
                      style: TextStyle(
                        color: isBleSupported
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          _SectionTitle(strings.about),
          _Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(strings.version),
                Text(
                  _version.isNotEmpty
                      ? '$_version (Flutter + SQLite)'
                      : strings.loading,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, prov, strings),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.restart_alt),
            label: Text(strings.resetData),
          ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog then resets all data.
  /// Context usage after async gaps is safely guarded with mounted checks.
  Future<void> _confirmReset(
    BuildContext context,
    SettingsProviderState prov,
    AppStrings strings,
  ) async {
    // Capture providers before async gaps to satisfy use_build_context_synchronously
    final readingsProv = context.read<ReadingsProvider>();
    final remindersProv = context.read<RemindersProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.resetData),
        content: Text(strings.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(strings.ok),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final db = DatabaseHelper();
    final database = await db.db;
    await database.delete('readings');
    await database.delete('reminders');
    await prov.reset();
    await readingsProv.load();
    await remindersProv.load();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(strings.resetDone)));
  }

  /// Parses a glucose input in the display unit and converts it back to
  /// mg/dL (the storage unit). Returns `null` for empty/invalid input.
  int? _parseGlucose(String raw, GlucoseUnit unit) {
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final n = double.tryParse(cleaned);
    if (n == null) return null;
    return unit == GlucoseUnit.mgDl ? n.round() : UnitConverter.mmolToMg(n);
  }

  Future<void> _update(
    SettingsProviderState prov, {
    Language? language,
    ThemeStyle? theme,
    DiabetesType? diabetesType,
    int? targetMin,
    int? targetMax,
    GlucoseUnit? unit,
    String? userName,
    bool? onboarded,
    double? heightCm,
    bool? usesInsulin,
  }) async {
    final next = prov.settings.copyWith(
      language: language,
      theme: theme,
      diabetesType: diabetesType,
      targetMin: targetMin,
      targetMax: targetMax,
      unit: unit,
      userName: userName,
      onboarded: onboarded,
      heightCm: heightCm,
      usesInsulin: usesInsulin,
    );

    // FIX-029 / BUG-005: validate before persisting so invalid ranges
    // (e.g. targetMin >= targetMax) never reach the DB.
    final validationError = next.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    await prov.persist(next);
  }

  Widget _choiceBtn(bool selected, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _styleRow(
    SettingsProviderState prov,
    Settings s,
    ThemeStyle style,
    String label,
    IconData icon,
  ) {
    final selected = s.theme == style;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _update(prov, theme: style),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

/// Google Drive backup sync card — least-privilege (drive.appdata scope
/// only): the app can touch its own hidden app-data folder and nothing else.
class _DriveSyncCard extends StatefulWidget {
  const _DriveSyncCard();

  @override
  State<_DriveSyncCard> createState() => _DriveSyncCardState();
}

class _DriveSyncCardState extends State<_DriveSyncCard> {
  GoogleSignInAccount? _account;
  DateTime? _lastBackup;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (DriveSyncService.isSupported) _restoreSession();
  }

  Future<void> _restoreSession() async {
    final account = await DriveSyncService().currentUser();
    if (!mounted) return;
    setState(() => _account = account);
    if (account != null) {
      final last = await DriveSyncService().lastBackupTime();
      if (mounted) setState(() => _lastBackup = last);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final account = await DriveSyncService().signIn();
      final last = await DriveSyncService().lastBackupTime();
      if (!mounted) return;
      setState(() {
        _account = account;
        _lastBackup = last;
      });
    } on Exception {
      _snack(AppStrings.of(context).driveSetupError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow() async {
    final strings = AppStrings.of(context);
    setState(() => _busy = true);
    try {
      final data = await collectExportData(context);
      final result = await DriveSyncService().uploadBackup(
        jsonEncode(data.toJson()),
      );
      if (!mounted) return;
      if (result.success) {
        setState(() => _lastBackup = result.lastBackupTime);
        _snack(strings.driveSynced);
      } else {
        _snack(strings.driveSetupError, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(strings.driveRestore),
        content: Text(strings.restoreConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(strings.ok),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final jsonStr = await DriveSyncService().downloadBackup();
      if (!mounted) return;
      if (jsonStr == null) {
        _snack(strings.driveNoBackupRestore);
        return;
      }
      final importResult = DataExporter.importFromJson(jsonStr);
      if (!importResult.success || importResult.data == null) {
        _snack(strings.importError, error: true);
        return;
      }
      await mergeImportedData(context, importResult.data!);
      if (!mounted) return;
      _snack(strings.driveRestored);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await DriveSyncService().signOut();
    if (!mounted) return;
    setState(() {
      _account = null;
      _lastBackup = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_sync, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.driveSync,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strings.drivePrivacyNote,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          if (!DriveSyncService.isSupported)
            Text(
              strings.driveUnsupported,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          else if (_account == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _signIn,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login, size: 18),
                label: Text(strings.driveSignIn),
              ),
            )
          else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  backgroundImage: _account!.photoUrl != null
                      ? NetworkImage(_account!.photoUrl!)
                      : null,
                  child: _account!.photoUrl == null
                      ? Text(
                          _account!.email.isNotEmpty
                              ? _account!.email[0].toUpperCase()
                              : '?',
                          style: TextStyle(fontSize: 12, color: primary),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.driveSignedInAs,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _account!.email,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _signOut,
                  child: Text(strings.driveSignOut),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _lastBackup != null
                  ? strings.driveLastBackup(
                      DateFormat(
                        'd MMM yyyy · HH:mm',
                        AppStrings.of(context).lang.code,
                      ).format(_lastBackup!.toLocal()),
                    )
                  : strings.driveNoBackup,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _syncNow,
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: Text(strings.driveSyncNow),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.cloud_download, size: 18),
                    label: Text(strings.driveRestore),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
