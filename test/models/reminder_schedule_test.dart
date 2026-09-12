// Tests for the v1.4 medication schedule model — weekday bits, multiple
// times per day, legacy fallback, and days-pattern summaries.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/reading.dart';
import 'package:glucotrack/models/reminder.dart';

Reminder _rem({
  int daysMask = WeekdayBits.everyDay,
  List<String> times = const [],
  String time = '08:00',
  ReminderKind kind = ReminderKind.medication,
}) => Reminder(
  id: 'r1',
  time: time,
  label: 'ميتفورمين · 500 ملغ',
  type: ReadingType.other,
  enabled: true,
  kind: kind,
  daysMask: daysMask,
  times: times,
);

void main() {
  group('WeekdayBits', () {
    test('everyDay sets all 7 bits and nothing else', () {
      expect(WeekdayBits.everyDay, 127);
      for (var d = 1; d <= 7; d++) {
        expect(
          WeekdayBits.isActive(WeekdayBits.everyDay, DateTime(2026, 9, d)),
          isTrue,
        );
      }
    });

    test('bitFor aligns with DateTime.weekday (Mon=1..Sun=7)', () {
      // 2026-09-07 is a Monday.
      expect(WeekdayBits.bitFor(DateTime(2026, 9, 7)), WeekdayBits.monday);
      expect(WeekdayBits.bitFor(DateTime(2026, 9, 12)), WeekdayBits.saturday);
      expect(WeekdayBits.bitFor(DateTime(2026, 9, 13)), WeekdayBits.sunday);
    });

    test('isActive honors a weekend-only mask', () {
      const weekend = WeekdayBits.saturday | WeekdayBits.sunday;
      expect(WeekdayBits.isActive(weekend, DateTime(2026, 9, 12)), isTrue);
      expect(WeekdayBits.isActive(weekend, DateTime(2026, 9, 9)), isFalse);
    });
  });

  group('Reminder schedule model', () {
    test('legacy row (single time, no times list) falls back to time', () {
      final r = _rem();
      expect(r.effectiveTimes, ['08:00']);
      expect(r.timesPerDay, 1);
    });

    test('multiple times are preserved and counted', () {
      final r = _rem(times: ['08:00', '14:00', '20:00']);
      expect(r.effectiveTimes, ['08:00', '14:00', '20:00']);
      expect(r.timesPerDay, 3);
    });

    test('DB round-trip keeps kind, days and times', () {
      final original = _rem(
        daysMask: WeekdayBits.monday | WeekdayBits.wednesday,
        times: ['09:30', '21:45'],
      );
      final restored = Reminder.fromDb(original.toDb());
      expect(restored.daysMask, original.daysMask);
      expect(restored.times, ['09:30', '21:45']);
      expect(restored.kind, ReminderKind.medication);
      expect(restored.effectiveTimes, ['09:30', '21:45']);
    });

    test('old row without days_mask/times reads with safe defaults', () {
      final r = Reminder.fromDb({
        'id': 'rem1',
        'time': '07:30',
        'label': 'قياس',
        'type': 'fasting',
        'enabled': 1,
        'kind': 'measurement',
      });
      expect(r.daysMask, WeekdayBits.everyDay);
      expect(r.effectiveTimes, ['07:30']);
      expect(r.kind, ReminderKind.measurement);
    });

    test('daysPattern recognizes everyday, weekend and custom masks', () {
      expect(_rem().daysPattern, 'every_day');
      expect(
        _rem(daysMask: WeekdayBits.saturday | WeekdayBits.sunday).daysPattern,
        'weekend',
      );
      expect(
        _rem(daysMask: WeekdayBits.monday | WeekdayBits.friday).daysPattern,
        'custom_days',
      );
    });

    test('measurement reminders stay every-day regardless of intent', () {
      // The provider forces everyDay for measurement kind at save time.
      final r = _rem(kind: ReminderKind.measurement, times: ['08:00']);
      expect(r.daysPattern, 'every_day');
    });
  });

  group('MedicationLogEntry', () {
    test('DB round-trip', () {
      final original = MedicationLogEntry(
        id: 'log1',
        reminderId: 'rem1',
        takenAt: DateTime(2026, 9, 12, 21, 30),
      );
      final restored = MedicationLogEntry.fromDb(original.toDb());
      expect(restored.id, 'log1');
      expect(restored.reminderId, 'rem1');
      expect(restored.takenAt, original.takenAt);
    });
  });
}
