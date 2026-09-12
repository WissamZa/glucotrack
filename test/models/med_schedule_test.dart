// Tests for the auto-generated dose schedule (MedSchedule) — the user only
// enters the first dose time; the rest must be sensible, deterministic and
// editable defaults.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/reminder.dart';

List<String> gen(String first, int count) =>
    MedSchedule.generateTimes(first, count);

void main() {
  group('MedSchedule.generateTimes', () {
    test('count 1 returns exactly the first time', () {
      expect(gen('08:00', 1), ['08:00']);
      expect(gen('23:15', 1), ['23:15']);
    });

    test('3 doses from a morning first time → classic 08/14/20', () {
      expect(gen('08:00', 3), ['08:00', '14:00', '20:00']);
    });

    test('2 doses → 12-hour spread capped at 6h spacing? no — 6h cap keeps '
        '2 doses 6h apart', () {
      // 08:00 with 2 doses: window 08:00–23:30 (930 min), spacing =
      // min(360, 930) = 360 → 08:00 + 20:00? No: 2 doses → 1 gap of 360 min
      // = 6h → 08:00, 14:00.
      expect(gen('08:00', 2), ['08:00', '14:00']);
    });

    test('4 doses compress evenly inside the waking window', () {
      // 08:00, 4 doses → span 930, spacing = 930~/3 = 310 → snapped 300 (5h)
      // → 08:00, 13:00, 18:00, 23:00.
      expect(gen('08:00', 4), ['08:00', '13:00', '18:00', '23:00']);
    });

    test('late first dose compresses spacing instead of skipping doses', () {
      // 14:00, 3 doses → span 570, spacing 285 → 14:00, 18:45, 23:30.
      expect(gen('14:00', 3), ['14:00', '18:45', '23:30']);
    });

    test('all generated times stay within the same day for morning starts', () {
      final times = gen('07:00', 4);
      for (final t in times) {
        final hour = int.parse(t.split(':').first);
        expect(hour, inInclusiveRange(7, 23), reason: 'time $t out of window');
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
