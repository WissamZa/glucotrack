// Reminder model — scheduled measurement reminder.
import 'reading.dart';

class Reminder {
  final String id;
  final String time; // "08:00"
  final String label;
  final ReadingType type;
  final bool enabled;

  const Reminder({
    required this.id,
    required this.time,
    required this.label,
    required this.type,
    required this.enabled,
  });

  Map<String, dynamic> toDb() => {
        'id': id,
        'time': time,
        'label': label,
        'type': type.dbValue,
        'enabled': enabled ? 1 : 0,
      };

  factory Reminder.fromDb(Map<String, dynamic> m) => Reminder(
        id: m['id'] as String,
        time: m['time'] as String,
        label: m['label'] as String,
        type: ReadingTypeX.fromDb(m['type'] as String),
        enabled: (m['enabled'] as int) == 1,
      );

  Reminder copyWith({
    String? id,
    String? time,
    String? label,
    ReadingType? type,
    bool? enabled,
  }) =>
      Reminder(
        id: id ?? this.id,
        time: time ?? this.time,
        label: label ?? this.label,
        type: type ?? this.type,
        enabled: enabled ?? this.enabled,
      );
}
