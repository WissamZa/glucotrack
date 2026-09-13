// Shared reminder add/edit dialog.
//
// Used by the Reminders screen (FAB + card taps) and the Medications tab /
// details page ("add a reminder for this drug" with prefilled name, id and
// dose form).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../i18n/strings.dart';
import '../models/medication_info.dart';
import '../models/reading.dart';
import '../models/reminder.dart';
import '../providers/providers.dart';
import '../services/medication_api_service.dart';

/// Opens the add/edit reminder dialog.
///
/// [prefillName]/[prefillRxcui]/[prefillFormKey] seed a NEW medication
/// reminder (used when adding from the Medications tab or a details page).
Future<void> showReminderEditor(
  BuildContext context, {
  Reminder? existing,
  String? prefillName,
  String? prefillRxcui,
  String? prefillFormKey,
}) {
  final strings = AppStrings.of(context);
  final editor = _ReminderEditorDialog(
    strings: strings,
    existing: existing,
    prefillName: prefillName,
    prefillRxcui: prefillRxcui,
    prefillFormKey: prefillFormKey,
  );
  return editor.open(context);
}

class _ReminderEditorDialog {
  _ReminderEditorDialog({
    required this.strings,
    required this.existing,
    required this.prefillName,
    required this.prefillRxcui,
    required this.prefillFormKey,
  });

  final AppStrings strings;
  final Reminder? existing;
  final String? prefillName;
  final String? prefillRxcui;
  final String? prefillFormKey;

  Future<void> open(BuildContext context) {
    final existing = this.existing;
    var kind =
        existing?.kind ??
        (prefillName != null
            ? ReminderKind.medication
            : ReminderKind.measurement);
    var type = existing?.type ?? ReadingType.fasting;
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final medNameCtrl = TextEditingController(
      text: existing != null && existing.kind == ReminderKind.medication
          ? (existing.doseForm != null || existing.doseAmount != null
                ? existing
                      .label // structured dose: label holds the name
                : existing.label.contains('·')
                ? existing.label.split('·').first.trim()
                : existing.label)
          : (prefillName ?? ''),
    );
    final doseAmountCtrl = TextEditingController(
      text: existing?.doseAmount != null
          ? _formatAmount(existing!.doseAmount!)
          : '',
    );
    String? doseFormKey = existing?.doseForm ?? prefillFormKey;
    String? rxcui = existing?.rxcui ?? prefillRxcui;
    var suggestions = const <MedicationInfo>[];
    var searching = false;
    Timer? debounce;
    // Times: the first dose seeds an auto-generated schedule; every time
    // stays individually editable.
    var doseCount = existing?.timesPerDay ?? 1;
    var times = existing != null
        ? List<String>.from(existing.effectiveTimes)
        : <String>['08:00'];
    var daysMask = existing?.daysMask ?? WeekdayBits.everyDay;

    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stx, setStx) => AlertDialog(
          title: Text(
            existing == null ? strings.addReminder : strings.editReminder,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.reminderKind,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      avatar: const Icon(Icons.water_drop, size: 15),
                      label: Text(
                        strings.kindMeasurement,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: kind == ReminderKind.measurement,
                      onSelected: (_) =>
                          setStx(() => kind = ReminderKind.measurement),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.medication_outlined, size: 15),
                      label: Text(
                        strings.kindMedication,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: kind == ReminderKind.medication,
                      onSelected: (_) =>
                          setStx(() => kind = ReminderKind.medication),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (kind == ReminderKind.measurement) ...[
                  // Single daily time (unchanged legacy behavior).
                  _sectionLabel(strings.reminderTime),
                  const SizedBox(height: 8),
                  _timeTile(stx, times.first, (t) {
                    setStx(() => times = [t]);
                  }),
                  const SizedBox(height: 16),
                  _sectionLabel(strings.measurementType),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ReadingType.values.map((t) {
                      final selected = type == t;
                      return ChoiceChip(
                        label: Text(
                          strings.readingType(t),
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: selected,
                        onSelected: (_) => setStx(() => type = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  _sectionLabel(strings.medicationName),
                  const SizedBox(height: 8),
                  TextField(
                    controller: medNameCtrl,
                    onChanged: (v) {
                      debounce?.cancel();
                      if (v.trim().length < 2) {
                        setStx(() => suggestions = const []);
                        return;
                      }
                      debounce = Timer(
                        const Duration(milliseconds: 400),
                        () async {
                          setStx(() => searching = true);
                          final results = await MedicationApiService().search(
                            v,
                          );
                          if (!stx.mounted) return;
                          setStx(() {
                            suggestions = results;
                            searching = false;
                          });
                        },
                      );
                    },
                    decoration: InputDecoration(
                      hintText: strings.searchMedication,
                      border: const OutlineInputBorder(),
                      suffixIcon: searching
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : (rxcui != null
                                ? IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    tooltip: strings.medicationDetails,
                                    onPressed: () => _openMedicationDetails(
                                      stx,
                                      rxcui!,
                                      medNameCtrl.text,
                                    ),
                                  )
                                : null),
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          for (final info in suggestions.take(5))
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.medication, size: 18),
                              title: Text(
                                info.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle:
                                  (info.synonym != null &&
                                      info.synonym != info.name)
                                  ? Text(
                                      info.synonym!,
                                      style: const TextStyle(fontSize: 11),
                                    )
                                  : null,
                              onTap: () {
                                medNameCtrl.text = info.name;
                                rxcui = info.rxcui;
                                doseFormKey ??= _doseFormKeyFromRxNorm(
                                  info.doseForm,
                                );
                                setStx(() => suggestions = const []);
                              },
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Structured dose: form dropdown + amount per dose.
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: doseFormKey,
                          decoration: InputDecoration(
                            labelText: strings.doseForm,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final key in _doseFormKeys)
                              DropdownMenuItem(
                                value: key,
                                child: Text(
                                  strings.doseFormLabel(key) ?? key,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                          ],
                          onChanged: (v) => setStx(() => doseFormKey = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: doseAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: strings.doseAmount,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Doses per day — the first dose seeds an auto schedule.
                  _sectionLabel(strings.doseCount),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final n in const [1, 2, 3, 4])
                        ChoiceChip(
                          label: Text(
                            '$n',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: doseCount == n,
                          onSelected: (_) => setStx(() {
                            doseCount = n;
                            times = MedSchedule.generateTimes(times.first, n);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel(
                    doseCount == 1
                        ? strings.reminderTime
                        : strings.firstDoseTime,
                  ),
                  const SizedBox(height: 8),
                  _timeTile(stx, times.first, (t) {
                    // Changing the first dose re-seeds the whole schedule.
                    setStx(
                      () => times = MedSchedule.generateTimes(t, doseCount),
                    );
                  }),
                  if (doseCount > 1) ...[
                    const SizedBox(height: 6),
                    Text(
                      strings.autoScheduleHint,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 1; i < times.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _timeTile(
                          stx,
                          times[i],
                          (t) => setStx(() => times[i] = t),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),

                  // Weekday selection.
                  _sectionLabel(strings.reminderDays),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var bit = 0; bit < 7; bit++)
                        FilterChip(
                          label: Text(
                            strings.weekdayShortNames()[bit],
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: (daysMask & (1 << bit)) != 0,
                          onSelected: (on) => setStx(() {
                            daysMask = on
                                ? (daysMask | (1 << bit))
                                : (daysMask & ~(1 << bit));
                            // Never allow an empty schedule.
                            if (daysMask == 0) daysMask = WeekdayBits.everyDay;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.daysPatternLabel(
                      Reminder(
                        id: 'tmp',
                        time: times.first,
                        label: '',
                        type: type,
                        enabled: true,
                        daysMask: daysMask,
                      ).daysPattern,
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _sectionLabel(strings.reminderLabel),
                const SizedBox(height: 8),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    hintText: kind == ReminderKind.measurement
                        ? strings.readingType(type)
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(strings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                debounce?.cancel();
                _saveReminder(
                  dialogCtx,
                  existing,
                  times,
                  daysMask,
                  type,
                  kind,
                  labelCtrl.text,
                  medNameCtrl.text,
                  doseFormKey,
                  doseAmountCtrl.text,
                  rxcui,
                  strings,
                );
              },
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
  );

  Widget _timeTile(
    BuildContext context,
    String current,
    ValueChanged<String> onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final parts = current.split(':');
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          ),
        );
        if (t != null) {
          onPicked(
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: 8),
            Text(current, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReminder(
    BuildContext dialogCtx,
    Reminder? existing,
    List<String> times,
    int daysMask,
    ReadingType type,
    ReminderKind kind,
    String labelText,
    String medName,
    String? doseFormKey,
    String doseAmountRaw,
    String? rxcui,
    AppStrings strings,
  ) async {
    final messenger = ScaffoldMessenger.of(dialogCtx);
    final prov = dialogCtx.read<RemindersProvider>();

    final sortedTimes = List<String>.from(times)..sort();

    final doseAmount = doseAmountRaw.trim().isEmpty
        ? null
        : double.tryParse(doseAmountRaw.trim().replaceAll(',', '.'));
    if (kind == ReminderKind.medication &&
        doseAmountRaw.trim().isNotEmpty &&
        doseAmount == null) {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorDoseAmount)));
      return;
    }

    String label;
    if (labelText.trim().isNotEmpty) {
      label = labelText.trim();
    } else if (kind == ReminderKind.medication) {
      final name = medName.trim();
      if (name.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.errorMedicationName)),
        );
        return;
      }
      label = name;
    } else {
      label = strings.readingType(type);
    }

    final reminder = Reminder(
      id: existing?.id ?? const Uuid().v4(),
      time: sortedTimes.first,
      label: label,
      type: type,
      enabled: existing?.enabled ?? true,
      kind: kind,
      daysMask: kind == ReminderKind.medication
          ? daysMask
          : WeekdayBits.everyDay,
      times: sortedTimes,
      doseForm: kind == ReminderKind.medication ? doseFormKey : null,
      doseAmount: kind == ReminderKind.medication ? doseAmount : null,
      rxcui: kind == ReminderKind.medication ? rxcui : null,
    );

    if (existing == null) {
      await prov.add(reminder);
    } else {
      await prov.update(reminder);
    }
    if (dialogCtx.mounted) {
      ScaffoldMessenger.of(dialogCtx)
          .showSnackBar(SnackBar(content: Text(strings.reminderAdded)));
    }
    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
  }

  // ── Medication helpers ──────────────────────────────────────────────────

  static const _doseFormKeys = [
    'tablet',
    'capsule',
    'ml',
    'drops',
    'spray',
    'cream',
    'injection',
    'units',
  ];

  static String _formatAmount(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// Maps an English RxNorm dose form to the app's stable dose-form key.
  static String? _doseFormKeyFromRxNorm(String? rxForm) {
    if (rxForm == null) return null;
    final f = rxForm.toLowerCase();
    if (f.contains('tablet')) return 'tablet';
    if (f.contains('capsule')) return 'capsule';
    if (f.contains('drop')) return 'drops';
    if (f.contains('aerosol') || f.contains('spray')) return 'spray';
    if (f.contains('cream') || f.contains('ointment') || f.contains('gel')) {
      return 'cream';
    }
    if (f.contains('inject')) return 'injection';
    if (f.contains('solution') ||
        f.contains('syrup') ||
        f.contains('liquid') ||
        f.contains('suspension')) {
      return 'ml';
    }
    return null;
  }

  void _openMedicationDetails(
    BuildContext context,
    String rxcui,
    String fallbackName,
  ) {
    Navigator.of(context).pushNamed(
      '/medication-details',
      arguments: {'rxcui': rxcui, 'name': fallbackName},
    );
  }
}
