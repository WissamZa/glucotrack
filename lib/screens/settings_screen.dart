import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../ble/ble_platform.dart';
import '../database/database_helper.dart';
import '../i18n/strings.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../services/webdav_sync_service.dart';
import '../utils/backup_crypto.dart';
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
          const _WebDavSyncCard(),
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

/// WebDAV backup-sync card — user-provided server (Nextcloud / Koofr /
/// self-hosted…), no developer registration, end-to-end encryption with a
/// user passphrase before anything leaves the phone.
class _WebDavSyncCard extends StatefulWidget {
  const _WebDavSyncCard();

  @override
  State<_WebDavSyncCard> createState() => _WebDavSyncCardState();
}

class _WebDavSyncCardState extends State<_WebDavSyncCard> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passphraseCtrl = TextEditingController();
  bool _encrypt = true;
  bool _editing = false; // show the config form
  bool _configured = false;
  bool _busy = false;
  bool _obscurePassphrase = true;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passphraseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await WebDavSyncService().loadConfig();
    final last = await WebDavSyncService().lastSyncTime();
    if (!mounted) return;
    setState(() {
      if (config != null) {
        _urlCtrl.text = config.url;
        _userCtrl.text = config.username;
        _passCtrl.text = config.password;
        _passphraseCtrl.text = config.passphrase;
        _encrypt = config.encrypt;
      }
      _configured = config != null && config.isComplete;
      _editing = !_configured;
      _lastSync = last;
    });
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

  WebDavConfig _configFromFields() => WebDavConfig(
    url: _urlCtrl.text.trim(),
    username: _userCtrl.text.trim(),
    password: _passCtrl.text,
    encrypt: _encrypt,
    passphrase: _passphraseCtrl.text,
  );

  Future<void> _saveAndTest() async {
    final strings = AppStrings.of(context);
    final config = _configFromFields();
    if (!config.baseUrl.startsWith('http') || config.username.isEmpty) {
      _snack(strings.errorTargetRangeInvalid, error: true);
      return;
    }
    if (config.encrypt && config.passphrase.isEmpty) {
      _snack(strings.webdavEncryptHint, error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final errorCode = await WebDavSyncService().testConnection(config);
      if (!mounted) return;
      if (errorCode != null) {
        _snack(
          strings.webdavTestFail(_errorLabel(strings, errorCode)),
          error: true,
        );
        return;
      }
      await WebDavSyncService().saveConfig(config);
      if (!mounted) return;
      setState(() {
        _configured = true;
        _editing = false;
      });
      _snack(strings.webdavTestOk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorLabel(AppStrings strings, String code) {
    switch (code) {
      case 'unauthorized':
        return strings.webdavPassword;
      case 'not_found':
        return strings.webdavUrl;
      case 'invalid_url':
        return strings.webdavUrl;
      case 'timeout':
        return strings.webdavNeverSynced;
      default:
        return code;
    }
  }

  Future<void> _syncNow() async {
    final strings = AppStrings.of(context);
    final config = await WebDavSyncService().loadConfig();
    if (config == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final data = await collectExportData(context);
      final result = await WebDavSyncService().uploadBackup(
        config,
        jsonEncode(data.toJson()),
      );
      if (!mounted) return;
      if (result.success) {
        setState(() => _lastSync = result.syncedAt);
        _snack(strings.webdavSynced);
      } else {
        _snack(strings.webdavTestFail(result.errorCode ?? ''), error: true);
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
        title: Text(strings.webdavRestore),
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

    final config = await WebDavSyncService().loadConfig();
    if (config == null || !mounted) return;
    setState(() => _busy = true);
    try {
      String? json;
      try {
        json = await WebDavSyncService().downloadBackup(config);
      } on BackupCryptoException catch (e) {
        if (!mounted) return;
        _snack(
          e.code == 'wrong_passphrase_or_corrupt'
              ? strings.webdavWrongPassphrase
              : strings.importError,
          error: true,
        );
        return;
      }
      if (!mounted) return;
      if (json == null) {
        _snack(strings.webdavNoBackupRestore);
        return;
      }
      final importResult = DataExporter.importFromJson(json);
      if (!importResult.success || importResult.data == null) {
        _snack(strings.importError, error: true);
        return;
      }
      await mergeImportedData(context, importResult.data!);
      if (!mounted) return;
      _snack(strings.webdavRestored);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    await WebDavSyncService().clearConfig();
    if (!mounted) return;
    setState(() {
      _configured = false;
      _editing = true;
      _lastSync = null;
      _passCtrl.clear();
      _passphraseCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

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
                child: const Icon(Icons.dns, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.webdavSync,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_configured && !_editing)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🔐 ${strings.webdavEncryptedBadge}',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                color: Colors.grey.shade500,
                tooltip: strings.webdavWhatIsTitle,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(strings.webdavWhatIsTitle),
                    content: SingleChildScrollView(
                      child: Text(
                        strings.webdavWhatIsBody,
                        style: const TextStyle(height: 1.6, fontSize: 13.5),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: Text(strings.ok),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.webdavDesc,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          if (_editing) ...[
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: strings.webdavUrl,
                hintText: 'https://cloud.example.com/remote.php/dav/files/user/glucotrack/',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userCtrl,
                    decoration: InputDecoration(
                      labelText: strings.webdavUsername,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: strings.webdavPassword,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.webdavEncrypt,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Switch(
                  value: _encrypt,
                  onChanged: (v) => setState(() => _encrypt = v),
                ),
              ],
            ),
            if (_encrypt) ...[
              TextField(
                controller: _passphraseCtrl,
                obscureText: _obscurePassphrase,
                decoration: InputDecoration(
                  labelText: strings.webdavPassphrase,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassphrase
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassphrase = !_obscurePassphrase,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.webdavEncryptHint,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _saveAndTest,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload, size: 18),
                label: Text(strings.webdavSaveTest),
              ),
            ),
          ] else ...[
            Text(
              _urlCtrl.text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _lastSync != null
                  ? strings.webdavLastSync(
                      DateFormat(
                        'd MMM yyyy · HH:mm',
                        strings.lang.code,
                      ).format(_lastSync!.toLocal()),
                    )
                  : strings.webdavNeverSynced,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _syncNow,
                    icon: const Icon(Icons.sync, size: 18),
                    label: Text(strings.webdavSyncNow),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.restore, size: 18),
                    label: Text(strings.webdavRestore),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(strings.webdavEdit),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  label: Text(strings.webdavRemove),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
