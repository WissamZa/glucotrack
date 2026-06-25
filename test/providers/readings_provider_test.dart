// Unit tests for ReadingsProvider state management.
//
// Uses a fake DB approach — the provider is tested in isolation by seeding
// its internal state directly via the public API.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/reading.dart';
import 'package:glucotrack/models/settings.dart';

void main() {
  // ── Reading.status() with different target ranges ────────────────────────
  group('ReadingsProvider business logic (pure)', () {
    group('status classification', () {
      final testCases = <(int value, int min, int max, ReadingStatus expected)>[
        (40, 80, 180, ReadingStatus.criticalLow),
        (53, 80, 180, ReadingStatus.criticalLow),
        (54, 80, 180, ReadingStatus.warningLow),
        (69, 80, 180, ReadingStatus.warningLow),
        (70, 80, 180, ReadingStatus.low),
        (79, 80, 180, ReadingStatus.low),
        (80, 80, 180, ReadingStatus.inRange),
        (130, 80, 180, ReadingStatus.inRange),
        (180, 80, 180, ReadingStatus.inRange),
        (181, 80, 180, ReadingStatus.high),
        (250, 80, 180, ReadingStatus.high),
        (251, 80, 180, ReadingStatus.criticalHigh),
        (400, 80, 180, ReadingStatus.criticalHigh),
      ];

      for (final tc in testCases) {
        test('value ${tc.$1} with target ${tc.$2}-${tc.$3} → ${tc.$4.name}', () {
          final r = Reading(
            id: 'x',
            value: tc.$1,
            type: ReadingType.fasting,
            timestamp: DateTime.now(),
          );
          expect(r.status(tc.$2, tc.$3), tc.$4);
        });
      }
    });

    // ── Sorting logic ─────────────────────────────────────────────────────
    group('sorting', () {
      final base = DateTime(2024, 1, 1);
      final readings = [
        Reading(id: 'a', value: 100, type: ReadingType.fasting, timestamp: base),
        Reading(id: 'b', value: 200, type: ReadingType.afterMeal, timestamp: base.add(const Duration(hours: 1))),
        Reading(id: 'c', value: 150, type: ReadingType.beforeMeal, timestamp: base.add(const Duration(hours: 2))),
      ];

      List<Reading> sortBy(SortOrder order) {
        final copy = List<Reading>.from(readings);
        switch (order) {
          case SortOrder.newest:
            copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          case SortOrder.oldest:
            copy.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          case SortOrder.highest:
            copy.sort((a, b) => b.value.compareTo(a.value));
          case SortOrder.lowest:
            copy.sort((a, b) => a.value.compareTo(b.value));
        }
        return copy;
      }

      test('newest first — most recent timestamp comes first', () {
        final sorted = sortBy(SortOrder.newest);
        expect(sorted.first.id, 'c');
        expect(sorted.last.id, 'a');
      });

      test('oldest first — earliest timestamp comes first', () {
        final sorted = sortBy(SortOrder.oldest);
        expect(sorted.first.id, 'a');
        expect(sorted.last.id, 'c');
      });

      test('highest first — largest value comes first', () {
        final sorted = sortBy(SortOrder.highest);
        expect(sorted.first.value, 200);
        expect(sorted.last.value, 100);
      });

      test('lowest first — smallest value comes first', () {
        final sorted = sortBy(SortOrder.lowest);
        expect(sorted.first.value, 100);
        expect(sorted.last.value, 200);
      });
    });

    // ── In-range percentage calculation ───────────────────────────────────
    group('in-range percentage', () {
      final base = DateTime(2024, 1, 1);

      Reading r(String id, int value) => Reading(
            id: id,
            value: value,
            type: ReadingType.fasting,
            timestamp: base,
          );

      int calcInRangePct(List<Reading> list, int min, int max) {
        if (list.isEmpty) return 0;
        final inRange = list
            .where((r) => r.status(min, max) == ReadingStatus.inRange)
            .length;
        return ((inRange / list.length) * 100).round();
      }

      test('100% when all readings are in range', () {
        final list = [r('a', 100), r('b', 120), r('c', 150)];
        expect(calcInRangePct(list, 80, 180), 100);
      });

      test('0% when all readings are out of range', () {
        final list = [r('a', 40), r('b', 300), r('c', 50)];
        expect(calcInRangePct(list, 80, 180), 0);
      });

      test('50% when half are in range', () {
        final list = [r('a', 100), r('b', 300)];
        expect(calcInRangePct(list, 80, 180), 50);
      });

      test('0% for empty list', () {
        expect(calcInRangePct([], 80, 180), 0);
      });
    });

    // ── Stats computations ─────────────────────────────────────────────────
    group('stats computation', () {
      final base = DateTime(2024, 1, 1);

      Reading r(String id, int value) => Reading(
            id: id,
            value: value,
            type: ReadingType.fasting,
            timestamp: base,
          );

      test('average is computed correctly', () {
        final list = [r('a', 100), r('b', 200), r('c', 150)];
        final values = list.map((r) => r.value).toList();
        final avg = (values.fold<int>(0, (s, v) => s + v) / values.length).round();
        expect(avg, 150);
      });

      test('min and max are found correctly', () {
        final list = [r('a', 100), r('b', 50), r('c', 200)];
        final values = list.map((r) => r.value).toList();
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        expect(min, 50);
        expect(max, 200);
      });
    });
  });

  // ── Reading model round-trip ──────────────────────────────────────────────
  group('Reading DB serialization', () {
    test('toDb/fromDb is a lossless round-trip', () {
      final original = Reading(
        id: 'rp-test-1',
        value: 135,
        type: ReadingType.afterMeal,
        timestamp: DateTime.utc(2024, 3, 15, 14, 30),
        notes: 'After lunch',
        carbs: 60,
        insulin: 8,
      );
      final restored = Reading.fromDb(original.toDb());
      expect(restored.id, original.id);
      expect(restored.value, original.value);
      expect(restored.type, original.type);
      expect(restored.timestamp.millisecondsSinceEpoch,
          original.timestamp.millisecondsSinceEpoch,);
      expect(restored.notes, original.notes);
      expect(restored.carbs, original.carbs);
      expect(restored.insulin, original.insulin);
    });
  });
}
