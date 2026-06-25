// Reminders screen — list, add, toggle, delete.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/reminder.dart';
import '../providers/providers.dart';

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
        onPressed: () => _showAddDialog(context, strings),
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
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey.shade400,),
                  const SizedBox(height: 12),
                  Text(
                    strings.noReminders,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = prov.reminders[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: r.enabled
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: r.enabled
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.time,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                r.label,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: r.enabled,
                          onChanged: (_) => prov.toggle(r.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20,),
                          tooltip: strings.tooltipDelete,
                          onPressed: () => _deleteReminder(context, prov, r.id, strings),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _deleteReminder(
    BuildContext context,
    RemindersProvider prov,
    String id,
    AppStrings strings,
  ) async {
    await prov.remove(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.reminderDeleted)),
    );
  }

  void _showAddDialog(BuildContext context, AppStrings strings) {
    String time = '08:00';
    ReadingType type = ReadingType.fasting;
    final labelCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stx, setStx) => AlertDialog(
          title: Text(strings.addReminder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.reminderTime,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: stx,
                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (t != null) {
                      setStx(() => time =
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',);
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
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        Text(time, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.measurementType,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
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
                Text(
                  strings.reminderLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    hintText: strings.readingType(type),
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
                time,
                type,
                labelCtrl.text,
                strings,
              ),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReminder(
    BuildContext dialogCtx,
    String time,
    ReadingType type,
    String labelText,
    AppStrings strings,
  ) async {
    final prov = context.read<RemindersProvider>();
    await prov.add(Reminder(
      id: const Uuid().v4(),
      time: time,
      label: labelText.trim().isEmpty ? strings.readingType(type) : labelText.trim(),
      type: type,
      enabled: true,
    ),);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.reminderAdded)),
      );
    }
    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
  }
}
