// Reminder model — scheduled measurement or medication reminder.
//
// v1.4 schedule model (DB v4):
//  - `daysMask`: bitmask of active weekdays (bit 0 = Monday … bit 6 = Sunday),
//    127 = every day. Reminders from v1.3 default to every day.
//  - `times`: one or more "HH:mm" times per day (medications often need
//    several doses). `time` is kept for backward compatibility — it always
//    mirrors the first entry of `times`.
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

/// Weekday bits for [Reminder.daysMask], aligned with DateTime.monday=1..7.
class WeekdayBits {
  WeekdayBits._();

  static const int monday = 1 << 0;
  static const int tuesday = 1 << 1;
  static const int wednesday = 1 << 2;
  static const int thursday = 1 << 3;
  static const int friday = 1 << 4;
  static const int saturday = 1 << 5;
  static const int sunday = 1 << 6;
  static const int everyDay = (1 << 7) - 1; // bits 0..6

  static int bitFor(DateTime day) => 1 << (day.weekday - 1);

  static bool isActive(int mask, DateTime day) => (mask & bitFor(day)) != 0;
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
  final String time; // "08:00" — legacy single time, mirrors times.first
  final String label;
  final ReadingType type;
  final bool enabled;
  final ReminderKind kind;
  final int daysMask; // bitmask of weekdays, 127 = every day
  final List<String> times; // "HH:mm" list (>= 1 entry)

  const Reminder({
    required this.id,
    required this.time,
    required this.label,
    required this.type,
    required this.enabled,
    this.kind = ReminderKind.measurement,
    this.daysMask = WeekdayBits.everyDay,
    this.times = const [],
  }) : assert(
         daysMask >= 1 && daysMask <= WeekdayBits.everyDay,
         'daysMask must set at least one weekday bit',
       );

  /// Effective times: the v1.4 `times` list, falling back to the legacy
  /// single `time` field for rows created before the upgrade.
  List<String> get effectiveTimes => times.isNotEmpty ? times : <String>[time];

  int get timesPerDay => effectiveTimes.length;

  /// Days summary pattern key: 'every_day' | 'weekdays' | 'weekend' |
  /// 'custom_days'. The UI localizes the value.
  String get daysPattern {
    switch (daysMask) {
      case WeekdayBits.everyDay:
        return 'every_day';
      case const (WeekdayBits.monday |
          WeekdayBits.tuesday |
          WeekdayBits.wednesday |
          WeekdayBits.thursday |
          WeekdayBits.friday):
        return 'weekdays';
      case const (WeekdayBits.saturday | WeekdayBits.sunday):
        return 'weekend';
      default:
        return 'custom_days';
    }
  }

  Map<String, dynamic> toDb() => {
    'id': id,
    'time': time,
    'label': label,
    'type': type.dbValue,
    'enabled': enabled ? 1 : 0,
    'kind': kind.dbValue,
    'days_mask': daysMask,
    'times': times.isEmpty ? null : times.join(','),
  };

  factory Reminder.fromDb(Map<String, dynamic> m) {
    final timesRaw = m['times'] as String?;
    final times = (timesRaw == null || timesRaw.isEmpty)
        ? const <String>[]
        : timesRaw.split(',');
    final time = m['time'] as String;
    return Reminder(
      id: m['id'] as String,
      time: time,
      label: m['label'] as String,
      type: ReadingTypeX.fromDb(m['type'] as String),
      enabled: (m['enabled'] as int) == 1,
      kind: ReminderKindX.fromDb(m['kind'] as String?),
      daysMask: (m['days_mask'] as int?) ?? WeekdayBits.everyDay,
      times: times,
    );
  }

  Reminder copyWith({
    Object? id = _unsetReminder,
    Object? time = _unsetReminder,
    Object? label = _unsetReminder,
    Object? type = _unsetReminder,
    Object? enabled = _unsetReminder,
    Object? kind = _unsetReminder,
    Object? daysMask = _unsetReminder,
    Object? times = _unsetReminder,
  }) => Reminder(
    id: identical(id, _unsetReminder) ? this.id : id as String,
    time: identical(time, _unsetReminder) ? this.time : time as String,
    label: identical(label, _unsetReminder) ? this.label : label as String,
    type: identical(type, _unsetReminder) ? this.type : type as ReadingType,
    enabled: identical(enabled, _unsetReminder)
        ? this.enabled
        : enabled as bool,
    kind: identical(kind, _unsetReminder) ? this.kind : kind as ReminderKind,
    daysMask: identical(daysMask, _unsetReminder)
        ? this.daysMask
        : daysMask as int,
    times: identical(times, _unsetReminder)
        ? this.times
        : times as List<String>,
  );
}

/// One "medication taken" event (DB v4 `medication_log`).
class MedicationLogEntry {
  final String id;
  final String reminderId;
  final DateTime takenAt;

  const MedicationLogEntry({
    required this.id,
    required this.reminderId,
    required this.takenAt,
  });

  Map<String, dynamic> toDb() => {
    'id': id,
    'reminder_id': reminderId,
    'taken_at': takenAt.millisecondsSinceEpoch,
  };

  factory MedicationLogEntry.fromDb(Map<String, dynamic> m) =>
      MedicationLogEntry(
        id: m['id'] as String,
        reminderId: m['reminder_id'] as String,
        takenAt: DateTime.fromMillisecondsSinceEpoch(m['taken_at'] as int),
      );
}
