// Tests for the auto-generated dose schedule (MedSchedule) — the user only
// enters the first dose time; the rest divide the 24-hour day evenly and
// stay individually editable.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/reminder.dart';

List<String> gen(String first, int count) =>
    MedSchedule.generateTimes(first, count);

void main() {
  group('MedSchedule.generateTimes — 24h division', () {
    test('count 1 returns exactly the first time', () {
      expect(gen('08:00', 1), ['08:00']);
      expect(gen('23:15', 1), ['23:15']);
    });

    test('3 doses → every 8 hours (wraps past midnight)', () {
      expect(gen('08:00', 3), ['08:00', '16:00', '00:00']);
    });

    test('2 doses → every 12 hours', () {
      expect(gen('08:00', 2), ['08:00', '20:00']);
    });

    test('4 doses → every 6 hours', () {
      expect(gen('08:00', 4), ['08:00', '14:00', '20:00', '02:00']);
    });

    test('late first dose divides the same way', () {
      expect(gen('14:00', 3), ['14:00', '22:00', '06:00']);
    });

    test('gaps between consecutive doses are exactly 24h/count', () {
      for (final count in [2, 3, 4, 6]) {
        final times = gen('09:15', count);
        final spacing = (24 * 60) ~/ count;
        for (var i = 1; i < times.length; i++) {
          final prev =
              int.parse(times[i - 1].split(':')[0]) * 60 +
              int.parse(times[i - 1].split(':')[1]);
          final cur =
              int.parse(times[i].split(':')[0]) * 60 +
              int.parse(times[i].split(':')[1]);
          final gap = (cur - prev + 24 * 60) % (24 * 60);
          expect(gap, spacing, reason: 'count=$count gap $i');
        }
      }
    });

    test('is deterministic — same input, same output', () {
      expect(gen('09:30', 3), gen('09:30', 3));
    });

    test('count is clamped to 1..6', () {
      expect(gen('08:00', 0).length, 1);
      expect(gen('08:00', 99).length, 6);
    });

    test('output format is always zero-padded HH:mm', () {
      final pattern = RegExp(r'^\d{2}:\d{2}$');
      for (final t in gen('06:05', 4)) {
        expect(pattern.hasMatch(t), isTrue, reason: 'bad format: $t');
      }
    });
  });
}
