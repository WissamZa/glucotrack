// Reminder model — scheduled measurement or medication reminder.
import 'reading.dart';

/// What kind of activity the reminder is for. Existing rows persisted before
/// v1.3.0 default to [measurement] (see DatabaseHelper v3 migration).
enum ReminderKind { measurement, medication }

extension ReminderKindX on ReminderKind {
  String get dbValue =>
      this == ReminderKind.medication ? 'medication' : 'measurement';

  static ReminderKind fromDb(String? s) =>
      s == 'medication' ? ReminderKind.medication : ReminderKind.measurement;
}

/// Sentinel object used by [Reminder.copyWith] to distinguish
/// "argument not supplied" from "argument explicitly null".
/// Defined separately here because the `_unset` sentinel in reading.dart
/// is file-private (Dart's underscore convention).
class _UnsetReminder {
  const _UnsetReminder();
}

const _unsetReminder = _UnsetReminder();

class Reminder {
  final String id;
  final String time; // "08:00"
  final String label;
  final ReadingType type;
  final bool enabled;
  final ReminderKind kind;

  const Reminder({
    required this.id,
    required this.time,
    required this.label,
    required this.type,
    required this.enabled,
    this.kind = ReminderKind.measurement,
  });

  Map<String, dynamic> toDb() => {
    'id': id,
    'time': time,
    'label': label,
    'type': type.dbValue,
    'enabled': enabled ? 1 : 0,
    'kind': kind.dbValue,
  };

  factory Reminder.fromDb(Map<String, dynamic> m) => Reminder(
    id: m['id'] as String,
    time: m['time'] as String,
    label: m['label'] as String,
    type: ReadingTypeX.fromDb(m['type'] as String),
    enabled: (m['enabled'] as int) == 1,
    kind: ReminderKindX.fromDb(m['kind'] as String?),
  );

  Reminder copyWith({
    Object? id = _unsetReminder,
    Object? time = _unsetReminder,
    Object? label = _unsetReminder,
    Object? type = _unsetReminder,
    Object? enabled = _unsetReminder,
    Object? kind = _unsetReminder,
  }) => Reminder(
    id: identical(id, _unsetReminder) ? this.id : id as String,
    time: identical(time, _unsetReminder) ? this.time : time as String,
    label: identical(label, _unsetReminder) ? this.label : label as String,
    type: identical(type, _unsetReminder) ? this.type : type as ReadingType,
    enabled: identical(enabled, _unsetReminder)
        ? this.enabled
        : enabled as bool,
    kind: identical(kind, _unsetReminder) ? this.kind : kind as ReminderKind,
  );
}
