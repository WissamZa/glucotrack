// Add/Edit Reading screen — full-screen modal.
//
// Supports two modes:
//   - Add: opens with empty form
//   - Edit: opens with pre-filled values from an existing reading
//
// The mode is determined by whether a Reading was passed via the route
// argument (see Navigator.pushNamed('/add', arguments: reading)).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../themes/app_theme.dart';

class AddReadingScreen extends StatefulWidget {
  const AddReadingScreen({super.key});

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _valueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _insulinCtrl = TextEditingController();
  late DateTime _timestamp;
  ReadingType _type = ReadingType.fasting;
  String? _editingId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // Default type based on time of day
    final h = DateTime.now().hour;
    if (h >= 6 && h < 9) {
      _type = ReadingType.fasting;
    } else if (h >= 9 && h < 11) {
      _type = ReadingType.afterMeal;
    } else if (h >= 11 && h < 14) {
      _type = ReadingType.beforeMeal;
    } else if (h >= 14 && h < 17) {
      _type = ReadingType.afterMeal;
    } else if (h >= 21) {
      _type = ReadingType.beforeSleep;
    } else {
      _type = ReadingType.other;
    }
    _timestamp = DateTime.now();

    // If a Reading was passed via arguments, enter edit mode
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Reading) {
      _editingId = arg.id;
      _valueCtrl.text = '${arg.value}';
      _type = arg.type;
      _notesCtrl.text = arg.notes ?? '';
      _carbsCtrl.text = arg.carbs != null ? '${arg.carbs}' : '';
      _insulinCtrl.text = arg.insulin != null ? '${arg.insulin}' : '';
      _timestamp = arg.timestamp;
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _notesCtrl.dispose();
    _carbsCtrl.dispose();
    _insulinCtrl.dispose();
    super.dispose();
  }

  int? get _numericValue => int.tryParse(_valueCtrl.text);
  bool get _isValid {
    final v = _numericValue;
    return v != null && v >= 20 && v <= 600;
  }

  void _adjust(int delta) {
    final cur = int.tryParse(_valueCtrl.text) ?? 0;
    final next = (cur + delta).clamp(0, 600);
    _valueCtrl.text = '$next';
    setState(() {});
  }

  Future<void> _save() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).invalidValue)),
      );
      return;
    }

    final v = _numericValue!;
    final notes = _notesCtrl.text.trim();
    final carbs = int.tryParse(_carbsCtrl.text);
    final insulin = int.tryParse(_insulinCtrl.text);

    final rProv = context.read<ReadingsProvider>();
    final strings = AppStrings.of(context);

    if (_editingId != null) {
      final existing = rProv.findById(_editingId!);
      if (existing != null) {
        await rProv.update(existing.copyWith(
          value: v,
          type: _type,
          timestamp: _timestamp,
          notes: notes.isEmpty ? null : notes,
          carbs: carbs,
          insulin: insulin,
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.editedSuccess)),
        );
        Navigator.pop(context);
      }
    } else {
      final id = 'r-${DateTime.now().millisecondsSinceEpoch}-${_type.name}';
      await rProv.add(Reading(
        id: id,
        value: v,
        type: _type,
        timestamp: _timestamp,
        notes: notes.isEmpty ? null : notes,
        carbs: carbs,
        insulin: insulin,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.savedSuccess)),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);
    final status = _isValid
        ? Reading(
            id: 'temp',
            value: _numericValue!,
            type: _type,
            timestamp: _timestamp,
          ).status(s.targetMin, s.targetMax)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_editingId != null) ...[
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 8),
            ],
            Text(_editingId != null ? strings.editReading : strings.addReading),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Glucose value card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('${strings.glucoseValue} (mg/dL)',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _adjust(-10),
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _valueCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: status != null
                                ? (status == ReadingStatus.inRange
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B))
                                : null,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '120',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => _adjust(10),
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [80, 120, 160, 200].map((v) {
                      final selected = _valueCtrl.text == '$v';
                      return ChoiceChip(
                        label: Text('$v'),
                        selected: selected,
                        onSelected: (_) {
                          _valueCtrl.text = '$v';
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      strings.statusLabel(status),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor(status),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Measurement type
          Text(strings.measurementType,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReadingType.values.map((t) {
              final selected = _type == t;
              return ChoiceChip(
                label: Text(strings.readingType(t)),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Timestamp
          Text(strings.time,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _timestamp,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d == null) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_timestamp),
              );
              if (t == null) return;
              setState(() {
                _timestamp = DateTime(d.year, d.month, d.day, t.hour, t.minute);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_timestamp.day}/${_timestamp.month}/${_timestamp.year} '
                    '${_timestamp.hour.toString().padLeft(2, '0')}:${_timestamp.minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Carbs + Insulin
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: strings.carbsGrams,
                  controller: _carbsCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: strings.insulinUnits,
                  controller: _insulinCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes
          Text(strings.notes,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: strings.notesPlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings.cancel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isValid ? _save : null,
                  icon: const Icon(Icons.check),
                  label: Text(strings.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _NumberField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
