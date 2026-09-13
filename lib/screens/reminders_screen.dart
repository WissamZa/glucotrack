// Reminders screen — list, add/edit, toggle, delete + medication schedule
// (days × times), a medication-taken log, structured doses and RxNorm
// autocomplete.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.dart';
import '../models/reminder.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../widgets/reminder_editor.dart';
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
        onPressed: () => showReminderEditor(context),
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
                        onEdit: () => showReminderEditor(context, existing: r),
                        onHistory: () => _showHistorySheet(context, r, strings),
                      )
                    : _MeasurementCard(
                        reminder: r,
                        onEdit: () => showReminderEditor(context, existing: r),
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

  // The add/edit dialog moved to widgets/reminder_editor.dart (shared with
  // the Medications tab and the details page).
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

  /// "1 حبة · 08:00 · 20:00 · كل الأيام" style subtitle.
  String _subtitle(Reminder reminder, AppStrings strings) {
    final parts = <String>[];
    final form = strings.doseFormLabel(reminder.doseForm);
    if (reminder.doseAmount != null) {
      final amount = reminder.doseAmount! % 1 == 0
          ? reminder.doseAmount!.toInt().toString()
          : reminder.doseAmount!.toString();
      parts.add(form != null ? '$amount $form' : amount);
    } else if (form != null) {
      parts.add(form);
    }
    parts.addAll(reminder.effectiveTimes);
    parts.add(strings.daysPatternLabel(reminder.daysPattern));
    return parts.join(' · ');
  }

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
        Row(
          children: [
            Expanded(
              child: Text(
                reminder.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (reminder.rxcui != null)
              InkWell(
                onTap: () => Navigator.of(context).pushNamed(
                  '/medication-details',
                  arguments: {'rxcui': reminder.rxcui, 'name': reminder.label},
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.info_outline,
                    size: 17,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            _subtitle(reminder, strings),
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
