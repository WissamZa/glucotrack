// Reminders screen — list, add/edit, toggle, delete + medication schedule
// (days × times) and a medication-taken log.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/reminder.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../widgets/screen_padding.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RemindersProvider>();
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.reminders),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: Text(
                '${prov.activeCount} / ${prov.reminders.length}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reminders_screen_add_reminder_fab',
        onPressed: () => _showReminderDialog(context, strings, null),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        tooltip: strings.addReminder,
        child: const Icon(Icons.add),
      ),
      body: prov.reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.noReminders,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              // Clear the BottomAppBar (MainShell) + system gesture inset so
              // the last card is fully reachable.
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                tabBarBottomClearance(context),
              ),
              itemCount: prov.reminders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = prov.reminders[i];
                return r.kind == ReminderKind.medication
                    ? _MedicationCard(
                        reminder: r,
                        onEdit: () => _showReminderDialog(context, strings, r),
                        onHistory: () => _showHistorySheet(context, r, strings),
                      )
                    : _MeasurementCard(
                        reminder: r,
                        onEdit: () => _showReminderDialog(context, strings, r),
                      );
              },
            ),
    );
  }

  // ── Medication history sheet ───────────────────────────────────────────
  void _showHistorySheet(
    BuildContext context,
    Reminder reminder,
    AppStrings strings,
  ) {
    final settings = context.read<SettingsProviderState>().settings;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollCtrl) {
          final log = sheetCtx.watch<RemindersProvider>().medicationLogFor(
            reminder.id,
          );
          return ListView.separated(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.paddingOf(sheetCtx).bottom + 16,
            ),
            itemCount: log.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Text(
                  '${strings.medicationHistory} — ${reminder.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                );
              }
              final entry = log[i - 1];
              final dateStr = DateFormat(
                'd MMMM yyyy · HH:mm',
                settings.language.code,
              ).format(entry.takenAt);
              return ListTile(
                leading: const Icon(Icons.check_circle, size: 20),
                dense: true,
                title: Text(dateStr, style: const TextStyle(fontSize: 13.5)),
              );
            },
          );
        },
      ),
    );
  }

  // ── Add / Edit dialog ───────────────────────────────────────────────────
  void _showReminderDialog(
    BuildContext context,
    AppStrings strings,
    Reminder? existing,
  ) {
    var kind = existing?.kind ?? ReminderKind.measurement;
    var type = existing?.type ?? ReadingType.fasting;
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final medNameCtrl = TextEditingController(
      text:
          (existing?.kind == ReminderKind.medication &&
              existing != null &&
              existing.label.contains('·'))
          ? existing.label.split('·').first.trim()
          : '',
    );
    final doseCtrl = TextEditingController(
      text:
          (existing?.kind == ReminderKind.medication &&
              existing != null &&
              existing.label.contains('·'))
          ? existing.label.split('·').skip(1).join('·').trim()
          : '',
    );
    // Times: editable list for medications; single time for measurements.
    var times = existing != null
        ? List<String>.from(existing.effectiveTimes)
        : <String>['08:00'];
    var daysMask = existing?.daysMask ?? WeekdayBits.everyDay;

    showDialog<void>(
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
                    decoration: InputDecoration(
                      hintText: strings.addMedication,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel(strings.medicationDose),
                  const SizedBox(height: 8),
                  TextField(
                    controller: doseCtrl,
                    decoration: InputDecoration(
                      hintText: '500 mg · 2 ${strings.insulinUnitsShort}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Multiple times per day.
                  _sectionLabel('${strings.timesPerDay} (${times.length})'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < times.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: _timeTile(
                            stx,
                            times[i],
                            (t) => setStx(() => times[i] = t),
                          ),
                        ),
                        if (times.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red.shade300,
                            tooltip: strings.delete,
                            onPressed: () => setStx(() => times.removeAt(i)),
                          ),
                      ],
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: stx,
                          initialTime: const TimeOfDay(hour: 20, minute: 0),
                        );
                        if (t == null) return;
                        final next =
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        if (times.contains(next)) {
                          if (stx.mounted) {
                            ScaffoldMessenger.of(stx).showSnackBar(
                              SnackBar(content: Text(strings.duplicateTime)),
                            );
                          }
                          return;
                        }
                        setStx(() => times.add(next));
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(strings.addTime),
                    ),
                  ),
                  const SizedBox(height: 8),

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
              onPressed: () => _saveReminder(
                dialogCtx,
                existing,
                times,
                daysMask,
                type,
                kind,
                labelCtrl.text,
                medNameCtrl.text,
                doseCtrl.text,
                strings,
              ),
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
    String dose,
    AppStrings strings,
  ) async {
    final messenger = ScaffoldMessenger.of(dialogCtx);
    final prov = dialogCtx.read<RemindersProvider>();

    final sortedTimes = List<String>.from(times)..sort();

    String label;
    if (labelText.trim().isNotEmpty) {
      label = labelText.trim();
    } else if (kind == ReminderKind.medication) {
      final name = medName.trim();
      final doseText = dose.trim();
      if (name.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.errorMedicationName)),
        );
        return;
      }
      label = doseText.isEmpty ? name : '$name · $doseText';
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
    );

    if (existing == null) {
      await prov.add(reminder);
    } else {
      await prov.update(reminder);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.reminderAdded)));
    }
    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────

class _ReminderCardShell extends StatelessWidget {
  final Reminder reminder;
  final IconData icon;
  final Color? iconColorOverride;
  final List<Widget> children;
  final VoidCallback? onEdit;

  const _ReminderCardShell({
    required this.reminder,
    required this.icon,
    required this.children,
    this.iconColorOverride,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final prov = context.watch<RemindersProvider>();
    final isMedication = reminder.kind == ReminderKind.medication;
    final accent = isMedication ? const Color(0xFF8B5CF6) : null;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: reminder.enabled
                      ? (accent ?? Theme.of(context).colorScheme.primary)
                            .withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: reminder.enabled
                      ? (iconColorOverride ??
                            Theme.of(context).colorScheme.primary)
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(children: children)),
              Switch(
                value: reminder.enabled,
                onChanged: (_) => prov.toggle(reminder.id),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                tooltip: strings.tooltipDelete,
                onPressed: () {
                  final prov = context.read<RemindersProvider>();
                  prov.remove(reminder.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.reminderDeleted)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;

  const _MeasurementCard({required this.reminder, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _ReminderCardShell(
      reminder: reminder,
      icon: Icons.access_time,
      onEdit: onEdit,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            reminder.time,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            reminder.label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            strings.kindMeasurement,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onHistory;

  const _MedicationCard({
    required this.reminder,
    required this.onEdit,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final prov = context.watch<RemindersProvider>();
    final taken = prov.takenTodayCount(reminder.id);
    final total = reminder.timesPerDay;
    final complete = taken >= total;
    final purple = const Color(0xFF8B5CF6);

    return _ReminderCardShell(
      reminder: reminder,
      icon: Icons.medication_outlined,
      iconColorOverride: purple,
      onEdit: onEdit,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            reminder.label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${reminder.effectiveTimes.join(' · ')}  ·  ${strings.daysPatternLabel(reminder.daysPattern)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                complete
                    ? strings.allDosesTaken
                    : strings.takenToday(taken, total),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: complete ? const Color(0xFF10B981) : purple,
                ),
              ),
            ),
            if (!complete)
              SizedBox(
                height: 30,
                child: ElevatedButton.icon(
                  onPressed: () => prov.markTaken(reminder.id),
                  icon: const Icon(Icons.check, size: 15),
                  label: Text(
                    strings.markTaken,
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.history, size: 19),
              color: Colors.grey.shade500,
              tooltip: strings.medicationHistory,
              onPressed: onHistory,
            ),
          ],
        ),
      ],
    );
  }
}
