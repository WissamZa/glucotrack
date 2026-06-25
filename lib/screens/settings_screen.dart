import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../ble/ble_platform.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: context.read<SettingsProviderState>().settings.userName);
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
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(strings.appearance),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(strings.language, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
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
                Row(children: [
                  Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(strings.displayStyle, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                _styleRow(prov, s, ThemeStyle.classic, strings.styleClassic, Icons.medical_services),
                _styleRow(prov, s, ThemeStyle.modern, strings.styleModern, Icons.nightlight),
                _styleRow(prov, s, ThemeStyle.elder, strings.styleElder, Icons.wb_sunny),
              ],
            ),
          ),

          _SectionTitle(strings.health),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.monitor_heart, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(strings.diabetesType, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
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
                        () => _update(prov, diabetesType: DiabetesType.gestational),
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
                Row(children: [
                  Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${strings.glucoseTargets} (mg/dL)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.targetMin,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: '${s.targetMin}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) _update(prov, targetMin: n.clamp(40, 150));
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
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: '${s.targetMax}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) _update(prov, targetMax: n.clamp(120, 300));
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

          _SectionTitle(strings.profile),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(strings.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
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
                        child: const Icon(Icons.upload_file, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.exportData,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              strings.importData,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Drive',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          strings.comingSoon,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      strings.comingSoon,
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    strings.comingSoonDesc,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // ── BLE Meter Sync — LIVE ─────────────────────────────────────
          _Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pushNamed('/sync'),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bluetooth_connected,
                      color: Colors.white, size: 22),
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
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Platform badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ]),
            ),
          ),

          _SectionTitle(strings.about),
          _Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(strings.version),
                Text(
                  '1.1.0 (Flutter + SQLite)',
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
    messenger.showSnackBar(
      SnackBar(content: Text(strings.resetDone)),
    );
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
    );

    // FIX-029 / BUG-005: validate before persisting so invalid ranges
    // (e.g. targetMin >= targetMax) never reach the DB.
    final validationError = next.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
        ),
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
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
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
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
